import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type DeleteAccountPayload = {
  app?: 'member' | 'owner';
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return jsonResponse({ error: 'Missing Supabase environment variables.' }, 500);
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Missing authorization header.' }, 401);
    }

    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user: caller },
      error: callerError,
    } = await callerClient.auth.getUser();

    if (callerError || !caller) {
      return jsonResponse({ error: 'Unauthorized.' }, 401);
    }

    let payload: DeleteAccountPayload = {};
    if (req.method !== 'GET') {
      try {
        payload = (await req.json()) as DeleteAccountPayload;
      } catch {
        payload = {};
      }
    }

    const app = payload.app === 'owner' ? 'owner' : 'member';
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: platformAdmin } = await adminClient
      .from('platform_admins')
      .select('user_id')
      .eq('user_id', caller.id)
      .maybeSingle();

    if (platformAdmin) {
      return jsonResponse(
        { error: 'Platform admin accounts cannot be deleted from the mobile app.' },
        403,
      );
    }

    const { data: memberLinks } = await adminClient
      .from('members')
      .select('id')
      .eq('user_id', caller.id);

    const { data: memberRoles } = await adminClient
      .from('gym_roles')
      .select('role')
      .eq('user_id', caller.id)
      .eq('role', 'member');

    const { data: staffRoles } = await adminClient
      .from('gym_roles')
      .select('role')
      .eq('user_id', caller.id)
      .in('role', ['owner', 'staff']);

    const hasMemberAppAccess =
      (memberLinks?.length ?? 0) > 0 || (memberRoles?.length ?? 0) > 0;
    const hasOwnerAppAccess = (staffRoles?.length ?? 0) > 0;

    if (app === 'member' && !hasMemberAppAccess) {
      return jsonResponse(
        { error: 'No member app account is linked to this login.' },
        403,
      );
    }

    if (app === 'owner' && !hasOwnerAppAccess) {
      return jsonResponse(
        { error: 'No gym owner or staff account is linked to this login.' },
        403,
      );
    }

    await adminClient.from('user_active_sessions').delete().eq('user_id', caller.id);

    if (hasMemberAppAccess) {
      const { error: memberCleanupError } = await adminClient
        .from('members')
        .update({
          user_id: null,
          address: null,
          emergency_contact: null,
          date_of_birth: null,
          weight_kg: null,
          height_cm: null,
          age: null,
          gender: null,
          fitness_goal: null,
          profile_setup_completed_at: null,
          profile_updated_at: null,
        })
        .eq('user_id', caller.id);

      if (memberCleanupError) {
        return jsonResponse({ error: memberCleanupError.message }, 500);
      }

      await adminClient
        .from('gym_roles')
        .delete()
        .eq('user_id', caller.id)
        .eq('role', 'member');
    }

    if (app === 'owner' && hasOwnerAppAccess) {
      const { error: staffRoleDeleteError } = await adminClient
        .from('gym_roles')
        .delete()
        .eq('user_id', caller.id)
        .in('role', ['owner', 'staff']);

      if (staffRoleDeleteError) {
        return jsonResponse({ error: staffRoleDeleteError.message }, 500);
      }
    }

    const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(caller.id);
    if (deleteUserError) {
      return jsonResponse({ error: deleteUserError.message }, 500);
    }

    return jsonResponse({
      success: true,
      deleted_user_id: caller.id,
      app,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error';
    return jsonResponse({ error: message }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
