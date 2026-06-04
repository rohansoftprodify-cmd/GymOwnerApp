import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type ResetPasswordPayload = {
  gym_id: string;
  member_id: string;
  password: string;
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

    const payload = (await req.json()) as ResetPasswordPayload;
    if (!payload.gym_id || !payload.member_id) {
      return jsonResponse({ error: 'gym_id and member_id are required.' }, 400);
    }
    if (!payload.password || payload.password.length < 6) {
      return jsonResponse({ error: 'Password must be at least 6 characters.' }, 400);
    }

    const { data: staffRole, error: staffRoleError } = await callerClient
      .from('gym_roles')
      .select('role')
      .eq('gym_id', payload.gym_id)
      .eq('user_id', caller.id)
      .in('role', ['owner', 'staff'])
      .maybeSingle();

    if (staffRoleError || !staffRole) {
      return jsonResponse({ error: 'You do not have permission for this gym.' }, 403);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: member, error: memberError } = await adminClient
      .from('members')
      .select('id, user_id, email, full_name')
      .eq('gym_id', payload.gym_id)
      .eq('id', payload.member_id)
      .maybeSingle();

    if (memberError || !member) {
      return jsonResponse({ error: 'Member not found.' }, 404);
    }

    if (!member.user_id) {
      return jsonResponse(
        { error: 'This member has no app login. Use “Create app login” instead.' },
        400,
      );
    }

    const { error: updateError } = await adminClient.auth.admin.updateUserById(
      member.user_id as string,
      { password: payload.password },
    );

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 400);
    }

    return jsonResponse(
      {
        success: true,
        email: member.email,
        message: 'Password updated. Share the new password with the member.',
      },
      200,
    );
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unexpected error.' },
      500,
    );
  }
});

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
