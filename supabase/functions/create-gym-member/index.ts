import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type CreateMemberPayload = {
  gym_id: string;
  full_name: string;
  phone: string;
  email: string;
  password: string;
  plan_id: string;
  start_date: string;
  payment_status?: 'paid' | 'partial' | 'due';
  amount_paid?: number;
  date_of_birth?: string | null;
  emergency_contact?: string | null;
  notes?: string | null;
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

    const payload = (await req.json()) as CreateMemberPayload;
    const validationError = validatePayload(payload);
    if (validationError) {
      return jsonResponse({ error: validationError }, 400);
    }

    const { data: staffRole, error: staffRoleError } = await callerClient
      .from('gym_roles')
      .select('role')
      .eq('gym_id', payload.gym_id)
      .eq('user_id', caller.id)
      .in('role', ['owner', 'staff'])
      .maybeSingle();

    if (staffRoleError || !staffRole) {
      return jsonResponse({ error: 'You do not have permission to create members for this gym.' }, 403);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: plan, error: planError } = await adminClient
      .from('subscription_plans')
      .select('id, duration_days, price, gym_id, is_active')
      .eq('id', payload.plan_id)
      .eq('gym_id', payload.gym_id)
      .eq('is_active', true)
      .maybeSingle();

    if (planError || !plan) {
      return jsonResponse({ error: 'Invalid or inactive plan for this gym.' }, 400);
    }

    const { data: createdUser, error: createUserError } = await adminClient.auth.admin.createUser({
      email: payload.email.trim().toLowerCase(),
      password: payload.password,
      email_confirm: true,
      user_metadata: {
        full_name: payload.full_name,
        app_role: 'member',
      },
    });

    if (createUserError || !createdUser.user) {
      return jsonResponse({ error: createUserError?.message ?? 'Failed to create auth user.' }, 400);
    }

    const userId = createdUser.user.id;
    const paymentStatus = payload.payment_status ?? 'due';
    const amountPaid = payload.amount_paid ?? 0;
    const endDate = addDays(payload.start_date, plan.duration_days as number);

    const { error: profileError } = await adminClient.from('profiles').upsert({
      id: userId,
      full_name: payload.full_name,
      phone: payload.phone,
    });

    if (profileError) {
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: profileError.message }, 400);
    }

    const { data: member, error: memberError } = await adminClient
      .from('members')
      .insert({
        gym_id: payload.gym_id,
        user_id: userId,
        full_name: payload.full_name,
        phone: payload.phone,
        email: payload.email.trim().toLowerCase(),
        date_of_birth: payload.date_of_birth,
        emergency_contact: payload.emergency_contact,
        notes: payload.notes,
        status: 'active',
      })
      .select('id, gym_id, full_name, email, phone, user_id, status, joined_on')
      .single();

    if (memberError || !member) {
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: memberError?.message ?? 'Failed to create member record.' }, 400);
    }

    const { error: roleError } = await adminClient.from('gym_roles').insert({
      gym_id: payload.gym_id,
      user_id: userId,
      role: 'member',
    });

    if (roleError) {
      await adminClient.from('members').delete().eq('id', member.id);
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: roleError.message }, 400);
    }

    const { error: subscriptionError } = await adminClient.from('member_subscriptions').insert({
      gym_id: payload.gym_id,
      member_id: member.id,
      plan_id: payload.plan_id,
      start_date: payload.start_date,
      end_date: endDate,
      payment_status: paymentStatus,
      amount_paid: amountPaid,
      status: 'active',
    });

    if (subscriptionError) {
      await adminClient.from('gym_roles').delete().eq('user_id', userId).eq('gym_id', payload.gym_id);
      await adminClient.from('members').delete().eq('id', member.id);
      await adminClient.auth.admin.deleteUser(userId);
      return jsonResponse({ error: subscriptionError.message }, 400);
    }

    return jsonResponse(
      {
        member,
        credentials: {
          email: payload.email.trim().toLowerCase(),
          password: payload.password,
        },
      },
      200,
    );
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : 'Unexpected error.' }, 500);
  }
});

function validatePayload(payload: CreateMemberPayload): string | null {
  if (!payload.gym_id) return 'gym_id is required.';
  if (!payload.full_name?.trim()) return 'full_name is required.';
  if (!payload.phone?.trim()) return 'phone is required.';
  if (!payload.email?.trim()) return 'email is required.';
  if (!payload.password || payload.password.length < 6) return 'password must be at least 6 characters.';
  if (!payload.plan_id) return 'plan_id is required.';
  if (!payload.start_date) return 'start_date is required.';
  return null;
}

function addDays(isoDate: string, days: number): string {
  const date = new Date(`${isoDate}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
