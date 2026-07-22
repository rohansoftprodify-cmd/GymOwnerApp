import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type ProvisionLoginPayload = {
  gym_id: string;
  member_id: string;
  password: string;
  phone?: string;
  email?: string;
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

    const payload = (await req.json()) as ProvisionLoginPayload;
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
      .select('id, user_id, email, full_name, phone')
      .eq('gym_id', payload.gym_id)
      .eq('id', payload.member_id)
      .maybeSingle();

    if (memberError || !member) {
      return jsonResponse({ error: 'Member not found.' }, 404);
    }

    if (member.user_id) {
      return jsonResponse(
        { error: 'Member already has app login. Use “Update password” instead.' },
        400,
      );
    }

    const phone = normalizePhone(payload.phone?.trim() || (member.phone as string | null) || '');
    if (!phone) {
      return jsonResponse({ error: 'Phone is required to create app login.' }, 400);
    }

    const emailRaw = (payload.email?.trim() || (member.email as string | null)?.trim() || '')
      .toLowerCase();
    const email = emailRaw.includes('@') ? emailRaw : null;

    const { data: createdUser, error: createUserError } = await adminClient.auth.admin.createUser({
      phone,
      password: payload.password,
      phone_confirm: true,
      ...(email ? { email, email_confirm: true } : {}),
      user_metadata: {
        full_name: member.full_name,
        app_role: 'member',
        login_phone: phone,
      },
    });

    if (createUserError || !createdUser.user) {
      return jsonResponse({ error: createUserError?.message ?? 'Failed to create auth user.' }, 400);
    }

    const userId = createdUser.user.id;

    const { error: profileError } = await adminClient.from('profiles').upsert({
      id: userId,
      full_name: member.full_name,
      phone,
    });

    if (profileError) {
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: profileError.message }, 400);
    }

    const memberPatch: Record<string, unknown> = { user_id: userId, phone };
    if (email) memberPatch.email = email;

    const { error: memberUpdateError } = await adminClient
      .from('members')
      .update(memberPatch)
      .eq('id', member.id)
      .eq('gym_id', payload.gym_id);

    if (memberUpdateError) {
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: memberUpdateError.message }, 400);
    }

    const { error: roleError } = await adminClient.from('gym_roles').insert({
      gym_id: payload.gym_id,
      user_id: userId,
      role: 'member',
    });

    if (roleError) {
      await adminClient.from('members').update({ user_id: null }).eq('id', member.id);
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: roleError.message }, 400);
    }

    return jsonResponse(
      {
        success: true,
        credentials: { phone, email, password: payload.password },
        message: 'App login created. Share credentials with the member.',
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

function normalizePhone(raw: string): string | null {
  const digits = raw.replace(/\D/g, '');
  if (!digits) return null;
  if (digits.length === 10) return `+91${digits}`;
  if (digits.length === 12 && digits.startsWith('91')) return `+${digits}`;
  if (digits.length >= 11 && digits.length <= 15) return `+${digits}`;
  return null;
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
