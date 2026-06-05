import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type ProvisionGymOwnerPayload = {
  gym_name: string;
  address?: string;
  gym_email?: string;
  owner_email: string;
  owner_password: string;
  owner_full_name: string;
  owner_phone?: string;
  timezone?: string;
  currency_code?: string;
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

    const { data: isSuperadmin, error: superadminError } = await callerClient.rpc(
      'current_user_is_superadmin',
    );

    if (superadminError || !isSuperadmin) {
      return jsonResponse({ error: 'Superadmin access required.' }, 403);
    }

    const payload = (await req.json()) as ProvisionGymOwnerPayload;
    if (!payload.gym_name?.trim() || !payload.owner_email?.trim() || !payload.owner_password) {
      return jsonResponse({ error: 'gym_name, owner_email, and owner_password are required.' }, 400);
    }
    if (!payload.owner_full_name?.trim()) {
      return jsonResponse({ error: 'owner_full_name is required.' }, 400);
    }
    if (payload.owner_password.length < 6) {
      return jsonResponse({ error: 'Password must be at least 6 characters.' }, 400);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: createdUser, error: createUserError } = await adminClient.auth.admin.createUser({
      email: payload.owner_email.trim().toLowerCase(),
      password: payload.owner_password,
      email_confirm: true,
      user_metadata: {
        full_name: payload.owner_full_name.trim(),
        app_role: 'owner',
      },
    });

    if (createUserError || !createdUser.user) {
      return jsonResponse({ error: createUserError?.message ?? 'Failed to create auth user.' }, 400);
    }

    const userId = createdUser.user.id;

    const { error: profileError } = await adminClient.from('profiles').upsert({
      id: userId,
      full_name: payload.owner_full_name.trim(),
      phone: payload.owner_phone?.trim() ?? null,
    });

    if (profileError) {
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: profileError.message }, 400);
    }

    const { data: gym, error: gymError } = await adminClient
      .from('gyms')
      .insert({
        name: payload.gym_name.trim(),
        address: payload.address?.trim() ?? null,
        email: payload.gym_email?.trim().toLowerCase() ?? payload.owner_email.trim().toLowerCase(),
        phone: payload.owner_phone?.trim() ?? null,
        timezone: payload.timezone ?? 'Asia/Kolkata',
        currency_code: payload.currency_code ?? 'INR',
        setup_completed_at: null,
      })
      .select('id, name, email, address')
      .single();

    if (gymError || !gym) {
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: gymError?.message ?? 'Failed to create gym.' }, 400);
    }

    const { error: roleError } = await adminClient.from('gym_roles').insert({
      gym_id: gym.id,
      user_id: userId,
      role: 'owner',
    });

    if (roleError) {
      await adminClient.from('gyms').delete().eq('id', gym.id);
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: roleError.message }, 400);
    }

    return jsonResponse(
      {
        success: true,
        gym,
        owner: {
          user_id: userId,
          email: payload.owner_email.trim().toLowerCase(),
          full_name: payload.owner_full_name.trim(),
        },
        message: 'Gym owner provisioned. Owner completes setup in the gym owner app on first login.',
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
