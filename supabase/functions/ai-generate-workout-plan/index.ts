import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { generateFromTemplate, type WorkoutPlanResult } from './workout_templates.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const DEFAULT_MONTHLY_AI_LIMIT = 5;

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function getAuthenticatedClient(req: Request): Promise<
  { client: SupabaseClient; userId: string } | Response
> {
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

async function assertGymStaff(client: SupabaseClient, gymId: string): Promise<boolean> {
  const { data, error } = await client.rpc('current_user_is_gym_member', { target_gym_id: gymId });
  if (error) return false;
  return Boolean(data);
}

function monthlyAiLimit(): number {
  const raw = Deno.env.get('WORKOUT_AI_MONTHLY_LIMIT') ?? Deno.env.get('DIET_AI_MONTHLY_LIMIT');
  const parsed = raw ? Number.parseInt(raw, 10) : DEFAULT_MONTHLY_AI_LIMIT;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MONTHLY_AI_LIMIT;
}

type GenerateWorkoutPayload = {
  gym_id: string;
  goal_key: 'weight_loss' | 'muscle_gain' | 'healthy';
  mode?: 'template' | 'ai' | 'quota' | 'adjust';
  experience_level?: 'beginner' | 'intermediate' | 'advanced';
  equipment_hint?: string;
  sessions_per_week?: number;
  duration_weeks?: number;
  member_age?: number;
  member_weight_kg?: number;
  workout_plan_id?: string;
  current_plan?: WorkoutPlanResult;
  completion_summary?: string;
};

const goalLabels: Record<string, string> = {
  weight_loss: 'fat loss and conditioning',
  muscle_gain: 'muscle gain and strength',
  healthy: 'general fitness and maintenance',
};

async function getAiQuota(client: SupabaseClient, gymId: string) {
  const limit = monthlyAiLimit();
  const { data, error } = await client.rpc('get_gym_ai_workout_quota', {
    p_gym_id: gymId,
    p_monthly_limit: limit,
  });
  if (error) throw new Error(error.message);
  return data as Record<string, unknown>;
}

async function consumeAiQuota(client: SupabaseClient, gymId: string) {
  const limit = monthlyAiLimit();
  const { data, error } = await client.rpc('consume_gym_ai_workout_quota', {
    p_gym_id: gymId,
    p_monthly_limit: limit,
  });
  if (error) throw new Error(error.message);
  return data as Record<string, unknown>;
}

async function fetchGymExercises(client: SupabaseClient, gymId: string): Promise<string[]> {
  const { data } = await client
    .from('exercises')
    .select('name')
    .eq('gym_id', gymId)
    .eq('is_active', true)
    .order('name');
  return (data ?? []).map((r: { name: string }) => r.name);
}

async function generateWithOpenAi(
  client: SupabaseClient,
  payload: GenerateWorkoutPayload,
  options?: { adjust?: boolean; completionSummary?: string; basePlan?: WorkoutPlanResult },
): Promise<WorkoutPlanResult> {
  const openAiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openAiKey) {
    throw new Error(
      'AI enhancement is not configured. Set OPENAI_API_KEY or use template generation.',
    );
  }

  const quota = await getAiQuota(client, payload.gym_id);
  if ((quota.remaining as number) <= 0) {
    throw new Error(
      `Monthly AI limit reached (${quota.used}/${quota.limit}). Use template generation or try again next month.`,
    );
  }

  const gymExercises = await fetchGymExercises(client, payload.gym_id);
  const goalLabel = goalLabels[payload.goal_key] ?? payload.goal_key;
  const level = payload.experience_level ?? 'beginner';
  const equipment = payload.equipment_hint?.trim() || 'full gym access';
  const spw = payload.sessions_per_week ?? 4;
  const weeks = payload.duration_weeks ?? 4;

  const systemPrompt = `You are an expert strength coach for gyms in India.
Return ONLY valid JSON (no markdown):
{
  "name": string,
  "description": string,
  "duration_weeks": number,
  "sessions_per_week": number,
  "experience_level": string,
  "equipment_hint": string,
  "sessions": [
    {
      "day_label": string,
      "day_number": number,
      "guidance": string,
      "exercises": [
        { "exercise_name": string, "sets": number, "reps": number, "rest_seconds": number, "notes": string }
      ]
    }
  ]
}
Prefer exercise names from the gym library when provided. Safe, progressive programming only.`;

  let userPrompt: string;
  if (options?.adjust && options.basePlan) {
    userPrompt = `Adjust this workout plan based on member completion history.
Current plan: ${JSON.stringify(options.basePlan)}
Completion history: ${options.completionSummary ?? 'Several sessions missed or skipped.'}
Rules: If sessions missed, suggest shorter alternatives. If fatigue/overtraining signs, add recovery/stretching days. Reduce volume 10-20% if needed. Keep same goal and equipment constraints.`;
  } else {
    userPrompt = `Create a ${spw}-day per week workout plan for ${weeks} weeks.
Goal: ${goalLabel}
Experience: ${level}
Equipment: ${equipment}
${payload.member_age ? `Age: ${payload.member_age}` : ''}
${payload.member_weight_kg ? `Weight: ${payload.member_weight_kg} kg` : ''}
${gymExercises.length ? `Gym exercise library (prefer these): ${gymExercises.slice(0, 40).join(', ')}` : ''}

Example style: "4-day muscle gain for beginner with dumbbells only" — push/pull/legs split.`;
  }

  const openAiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openAiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.7,
    }),
  });

  if (!openAiResponse.ok) {
    throw new Error(`AI request failed: ${await openAiResponse.text()}`);
  }

  const completion = await openAiResponse.json();
  const content = completion?.choices?.[0]?.message?.content;
  if (!content || typeof content !== 'string') throw new Error('AI returned an empty response.');

  let plan: WorkoutPlanResult;
  try {
    plan = JSON.parse(content) as WorkoutPlanResult;
  } catch {
    throw new Error('AI returned invalid JSON.');
  }

  if (!plan.name || !Array.isArray(plan.sessions) || plan.sessions.length === 0) {
    throw new Error('AI plan is missing required fields.');
  }

  const consumed = await consumeAiQuota(client, payload.gym_id);
  if (!consumed.allowed) {
    throw new Error('Monthly AI limit reached while completing the request.');
  }

  return plan;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const auth = await getAuthenticatedClient(req);
    if (auth instanceof Response) return auth;

    const payload = (await req.json()) as GenerateWorkoutPayload;
    if (!payload.gym_id || !payload.goal_key) {
      return jsonResponse({ error: 'gym_id and goal_key are required.' }, 400);
    }

    const mode = payload.mode ?? 'template';
    const isAdjust = mode === 'adjust';

    if (!isAdjust) {
      const allowed = await assertGymStaff(auth.client, payload.gym_id);
      if (!allowed) return jsonResponse({ error: 'Unauthorized for this gym.' }, 403);
    }

    if (mode === 'quota') {
      const quota = await getAiQuota(auth.client, payload.gym_id);
      return jsonResponse({ success: true, quota }, 200);
    }

    if (mode === 'template') {
      const plan = generateFromTemplate({
        goal_key: payload.goal_key,
        experience_level: payload.experience_level,
        equipment_hint: payload.equipment_hint,
        sessions_per_week: payload.sessions_per_week,
        duration_weeks: payload.duration_weeks,
        member_age: payload.member_age,
        member_weight_kg: payload.member_weight_kg,
      });
      return jsonResponse({ success: true, source: 'template', plan }, 200);
    }

    if (mode === 'ai') {
      const plan = await generateWithOpenAi(auth.client, payload);
      const quota = await getAiQuota(auth.client, payload.gym_id);
      return jsonResponse({ success: true, source: 'ai', plan, quota }, 200);
    }

    if (mode === 'adjust') {
      let basePlan = payload.current_plan;
      let completionSummary = payload.completion_summary;

      if (payload.workout_plan_id) {
        const { data: detail } = await auth.client.rpc('get_my_workout_plan_detail', {
          p_workout_plan_id: payload.workout_plan_id,
        });
        if (detail && typeof detail === 'object') {
          const d = detail as Record<string, unknown>;
          basePlan = {
            name: d.name as string,
            description: d.description as string,
            duration_weeks: d.duration_weeks as number,
            sessions_per_week: d.sessions_per_week as number,
            experience_level: d.experience_level as string,
            equipment_hint: d.equipment_hint as string,
            sessions: d.sessions as WorkoutPlanResult['sessions'],
          };
        }
        const { data: logs } = await auth.client.rpc('get_my_workout_completion_summary', {
          p_workout_plan_id: payload.workout_plan_id,
        });
        if (Array.isArray(logs) && logs.length > 0) {
          completionSummary = JSON.stringify(logs);
        }
      }

      if (!basePlan) {
        return jsonResponse({ error: 'current_plan or workout_plan_id required for adjust mode.' }, 400);
      }

      const plan = await generateWithOpenAi(auth.client, payload, {
        adjust: true,
        basePlan,
        completionSummary: completionSummary ?? 'Member missed recent sessions.',
      });
      const quota = await getAiQuota(auth.client, payload.gym_id);
      return jsonResponse({ success: true, source: 'ai_adjust', plan, quota }, 200);
    }

    return jsonResponse({ error: 'Invalid mode. Use template, ai, quota, or adjust.' }, 400);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unexpected error.' },
      500,
    );
  }
});
