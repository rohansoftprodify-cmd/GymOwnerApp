import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const DEFAULT_MONTHLY_LIMIT = 100;

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function getAuthenticatedClient(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  if (!supabaseUrl || !anonKey) {
    return jsonResponse({ error: 'Missing Supabase environment variables.' }, 500);
  }
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return jsonResponse({ error: 'Missing authorization header.' }, 401);

  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user) return jsonResponse({ error: 'Unauthorized.' }, 401);
  return { client, userId: user.id };
}

function monthlyLimit(): number {
  const raw = Deno.env.get('COACH_CHAT_MONTHLY_LIMIT');
  const parsed = raw ? Number.parseInt(raw, 10) : DEFAULT_MONTHLY_LIMIT;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MONTHLY_LIMIT;
}

async function getQuota(client: SupabaseClient, gymId: string) {
  const { data, error } = await client.rpc('get_gym_ai_coach_chat_quota', {
    p_gym_id: gymId,
    p_monthly_limit: monthlyLimit(),
  });
  if (error) throw new Error(error.message);
  return data as Record<string, unknown>;
}

async function consumeQuota(client: SupabaseClient, gymId: string) {
  const { data, error } = await client.rpc('consume_gym_ai_coach_chat_quota', {
    p_gym_id: gymId,
    p_monthly_limit: monthlyLimit(),
  });
  if (error) throw new Error(error.message);
  return data as Record<string, unknown>;
}

type ChatTurn = { role: 'user' | 'assistant'; content: string };

type MemberContext = {
  gym_id: string;
  member?: Record<string, unknown>;
  gym?: Record<string, unknown>;
  subscription?: Record<string, unknown>;
  attendance?: Record<string, unknown>;
  diet_plans?: unknown[];
  workout_plans?: unknown[];
  recent_workout_logs?: unknown[];
};

function buildSystemPrompt(ctx: MemberContext): string {
  const member = ctx.member ?? {};
  const gym = ctx.gym ?? {};
  const attendance = ctx.attendance ?? {};

  return `You are a friendly 24/7 AI fitness coach for gym members in India.
Answer in clear, practical language. Use metric units. Give realistic nutrition estimates for Indian foods (roti, paneer, dal, rice, etc.).
When discussing workouts, prefer the member's assigned gym plans when available.
You are not a doctor — add a brief disclaimer for medical/injury concerns.
Keep answers concise (under 180 words unless the user asks for detail).

Member context:
- Name: ${member.full_name ?? 'Member'}
- Age: ${member.age ?? 'unknown'}
- Weight: ${member.weight_kg ?? 'unknown'} kg
- Height: ${member.height_cm ?? 'unknown'} cm
- BMI: ${member.bmi ?? 'unknown'}
- Fitness goal: ${member.fitness_goal ?? 'not set'}
- Gym: ${gym.name ?? 'Gym'}
- Total gym visits: ${attendance.total_visits ?? 0}
- Visits last 30 days: ${attendance.visits_last_30_days ?? 0}
- Assigned diet plans: ${JSON.stringify(ctx.diet_plans ?? [])}
- Assigned workout plans: ${JSON.stringify(ctx.workout_plans ?? [])}
- Recent workout logs: ${JSON.stringify(ctx.recent_workout_logs ?? [])}`;
}

function fallbackReply(message: string, ctx: MemberContext): string {
  const lower = message.toLowerCase();
  const goal = (ctx.member?.fitness_goal as string) ?? 'healthy';
  const visits30 = (ctx.attendance?.visits_last_30_days as number) ?? 0;
  const workouts = (ctx.workout_plans as { name?: string; sessions_per_week?: number }[]) ?? [];

  if (lower.includes('roti') && lower.includes('paneer')) {
    return 'Rough estimate for 2 medium wheat rotis (~70–80 kcal each) plus ~100 g paneer bhurji or grilled paneer (~260–320 kcal): about **420–480 kcal** total, with ~18–22 g protein depending on oil used. For accuracy, specify portion size and cooking style. Pair with salad for fiber.';
  }
  if (lower.includes('workout') && (lower.includes('today') || lower.includes('should i do'))) {
    const plan = workouts[0];
    if (plan?.name) {
      return `Based on your plan **${plan.name}**, pick the next scheduled session you have not completed recently. If you trained hard yesterday, choose a lighter upper-body or mobility day. Aim for ${plan.sessions_per_week ?? 3} sessions per week consistently. Warm up 5 minutes before you start.`;
    }
    return 'For today: if you trained legs yesterday, focus on upper body or a 30-minute brisk walk + core. If you have been inactive 3+ days, start with a full-body circuit (squats, push-ups, rows) for 25–30 minutes at moderate effort.';
  }
  if (lower.includes('not losing weight') || lower.includes("isn't losing") || lower.includes('weight loss')) {
    return `Plateaus are common. Check: (1) **Calorie deficit** — even healthy foods add up; track for 1 week. (2) **Protein** — aim ~1.6–2 g/kg if your goal is ${goal}. (3) **Steps & training** — you logged ${visits30} visits in 30 days; consistency beats intensity. (4) **Sleep & stress**. (5) **Water retention** after new training. Give changes 2–3 weeks. For personalized macros, follow your gym diet plan or ask your trainer.`;
  }
  if (lower.includes('calorie') || lower.includes('calories')) {
    return 'Share the exact foods and portions (e.g. "2 rotis + 1 katori dal + salad") and I can estimate calories and protein. Indian home meals vary a lot based on oil and serving size.';
  }
  return 'I can help with Indian meal calories, today\'s workout ideas, and weight-loss plateaus. Try asking: "How many calories in 2 rotis and paneer?" or "What workout should I do today?" For gym timings and membership, use Gym Support in the app.';
}

async function chatWithOpenAi(
  systemPrompt: string,
  history: ChatTurn[],
  message: string,
): Promise<string> {
  const openAiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openAiKey) throw new Error('OPENAI_NOT_CONFIGURED');

  const messages = [
    { role: 'system', content: systemPrompt },
    ...history.slice(-8).map((t) => ({ role: t.role, content: t.content })),
    { role: 'user', content: message },
  ];

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openAiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4o-mini',
      messages,
      temperature: 0.65,
      max_tokens: 500,
    }),
  });

  if (!response.ok) {
    throw new Error(`AI request failed: ${await response.text()}`);
  }

  const completion = await response.json();
  const content = completion?.choices?.[0]?.message?.content;
  if (!content || typeof content !== 'string') {
    throw new Error('AI returned an empty response.');
  }
  return content.trim();
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const auth = await getAuthenticatedClient(req);
    if (auth instanceof Response) return auth;

    const body = await req.json() as {
      message?: string;
      history?: ChatTurn[];
      mode?: 'chat' | 'quota';
    };

    const { data: ctxRaw, error: ctxError } = await auth.client.rpc('get_member_fitness_chat_context');
    if (ctxError || !ctxRaw || typeof ctxRaw !== 'object') {
      return jsonResponse({ error: 'No gym membership linked to this account.' }, 403);
    }

    const ctx = ctxRaw as MemberContext;
    const gymId = ctx.gym_id;
    if (!gymId) return jsonResponse({ error: 'Gym context missing.' }, 400);

    if (body.mode === 'quota') {
      const quota = await getQuota(auth.client, gymId);
      return jsonResponse({ success: true, quota }, 200);
    }

    const message = body.message?.trim();
    if (!message) return jsonResponse({ error: 'message is required.' }, 400);

    const quota = await getQuota(auth.client, gymId);
    if ((quota.remaining as number) <= 0) {
      return jsonResponse({
        error: `Monthly chat limit reached (${quota.used}/${quota.limit}). Try again next month.`,
        quota,
      }, 429);
    }

    const history = Array.isArray(body.history) ? body.history : [];
    const systemPrompt = buildSystemPrompt(ctx);

    let reply: string;
    let source: 'ai' | 'fallback' = 'ai';

    try {
      reply = await chatWithOpenAi(systemPrompt, history, message);
      const consumed = await consumeQuota(auth.client, gymId);
      if (!consumed.allowed) {
        return jsonResponse({ error: 'Monthly chat limit reached.' }, 429);
      }
      const updatedQuota = await getQuota(auth.client, gymId);
      return jsonResponse({
        success: true,
        reply,
        source,
        quota: updatedQuota,
      }, 200);
    } catch (err) {
      if (err instanceof Error && err.message === 'OPENAI_NOT_CONFIGURED') {
        source = 'fallback';
        reply = fallbackReply(message, ctx);
        const consumed = await consumeQuota(auth.client, gymId);
        if (!consumed.allowed) {
          return jsonResponse({ error: 'Monthly chat limit reached.' }, 429);
        }
        const updatedQuota = await getQuota(auth.client, gymId);
        return jsonResponse({ success: true, reply, source, quota: updatedQuota }, 200);
      }
      throw err;
    }
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unexpected error.' },
      500,
    );
  }
});
