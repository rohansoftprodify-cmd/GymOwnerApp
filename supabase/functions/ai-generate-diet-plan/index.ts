import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { generateFromTemplate, type DietPlanResult } from './diet_templates.ts';

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

async function getAuthenticatedGymClient(req: Request): Promise<{
  client: SupabaseClient;
  userId: string;
} | Response> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

  if (!supabaseUrl || !anonKey) {
    return jsonResponse({ error: 'Missing Supabase environment variables.' }, 500);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'Missing authorization header.' }, 401);
  }

  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    return jsonResponse({ error: 'Unauthorized.' }, 401);
  }

  return { client, userId: user.id };
}

async function assertGymStaff(client: SupabaseClient, gymId: string): Promise<boolean> {
  const { data, error } = await client.rpc('current_user_is_gym_member', {
    target_gym_id: gymId,
  });
  if (error) return false;
  return Boolean(data);
}

function monthlyAiLimit(): number {
  const raw = Deno.env.get('DIET_AI_MONTHLY_LIMIT');
  const parsed = raw ? Number.parseInt(raw, 10) : DEFAULT_MONTHLY_AI_LIMIT;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MONTHLY_AI_LIMIT;
}

type GenerateDietPlanPayload = {
  gym_id: string;
  goal_key: 'weight_loss' | 'muscle_gain' | 'healthy';
  mode?: 'template' | 'ai';
  target_calories?: number;
  dietary_preference?: 'veg' | 'non_veg' | 'eggetarian';
  member_weight_kg?: number;
  cuisine_hint?: string;
};

type AiDietPlan = DietPlanResult;

const goalLabels: Record<string, string> = {
  weight_loss: 'weight loss (moderate calorie deficit)',
  muscle_gain: 'muscle gain (lean surplus, high protein)',
  healthy: 'healthy maintenance and balanced nutrition',
};

async function getAiQuota(client: SupabaseClient, gymId: string) {
  const limit = monthlyAiLimit();
  const { data, error } = await client.rpc('get_gym_ai_diet_quota', {
    p_gym_id: gymId,
    p_monthly_limit: limit,
  });
  if (error) throw new Error(error.message);
  return data as Record<string, unknown>;
}

async function consumeAiQuota(client: SupabaseClient, gymId: string) {
  const limit = monthlyAiLimit();
  const { data, error } = await client.rpc('consume_gym_ai_diet_quota', {
    p_gym_id: gymId,
    p_monthly_limit: limit,
  });
  if (error) throw new Error(error.message);
  return data as Record<string, unknown>;
}

async function generateWithOpenAi(
  client: SupabaseClient,
  payload: GenerateDietPlanPayload,
): Promise<AiDietPlan> {
  const openAiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openAiKey) {
    throw new Error(
      'AI enhancement is not configured. Set OPENAI_API_KEY in Supabase Edge Function secrets, or use template generation.',
    );
  }

  const quota = await getAiQuota(client, payload.gym_id);
  if ((quota.remaining as number) <= 0) {
    throw new Error(
      `Monthly AI limit reached (${quota.used}/${quota.limit}). Use template generation or try again next month.`,
    );
  }

  const { data: gym } = await client
    .from('gyms')
    .select('name')
    .eq('id', payload.gym_id)
    .maybeSingle();

  const goalLabel = goalLabels[payload.goal_key] ?? payload.goal_key;
  const calories = payload.target_calories ?? 2000;
  const dietPref = payload.dietary_preference ?? 'veg';
  const weight = payload.member_weight_kg;
  const cuisine = payload.cuisine_hint?.trim() || 'Indian gym-friendly home foods';

  const systemPrompt = `You are an expert sports nutritionist for gyms in India.
Return ONLY valid JSON matching this schema (no markdown):
{
  "name": string,
  "description": string,
  "target_calories": number,
  "target_protein_g": number,
  "target_carbs_g": number,
  "target_fat_g": number,
  "hydration_liters": number,
  "duration_days": number,
  "meals": [
    {
      "meal_label": string,
      "meal_time": string,
      "guidance": string,
      "foods": [
        {
          "food_name": string,
          "portion": string,
          "calories": number,
          "protein_g": number,
          "carbs_g": number,
          "fat_g": number,
          "notes": string
        }
      ]
    }
  ]
}
Include 4-6 meals per day. Use realistic portions and macros that sum close to daily targets.`;

  const userPrompt = `Create a 7-day diet plan template for a gym member.
Gym: ${gym?.name ?? 'Gym'}
Goal: ${goalLabel}
Target calories/day: ${calories}
Diet: ${dietPref}
Cuisine/style: ${cuisine}
${weight ? `Member weight: ${weight} kg` : ''}

Use practical Indian gym foods (dal, roti, rice, paneer, eggs if allowed, oats, curd, chicken if non-veg, etc.).`;

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
    const errText = await openAiResponse.text();
    throw new Error(`AI request failed: ${errText}`);
  }

  const completion = await openAiResponse.json();
  const content = completion?.choices?.[0]?.message?.content;
  if (!content || typeof content !== 'string') {
    throw new Error('AI returned an empty response.');
  }

  let plan: AiDietPlan;
  try {
    plan = JSON.parse(content) as AiDietPlan;
  } catch {
    throw new Error('AI returned invalid JSON.');
  }

  if (!plan.name || !Array.isArray(plan.meals) || plan.meals.length === 0) {
    throw new Error('AI plan is missing required fields.');
  }

  const consumed = await consumeAiQuota(client, payload.gym_id);
  if (!consumed.allowed) {
    throw new Error('Monthly AI limit reached while completing the request.');
  }

  return plan;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const auth = await getAuthenticatedGymClient(req);
    if (auth instanceof Response) return auth;

    const payload = (await req.json()) as GenerateDietPlanPayload;
    if (!payload.gym_id || !payload.goal_key) {
      return jsonResponse({ error: 'gym_id and goal_key are required.' }, 400);
    }

    const allowed = await assertGymStaff(auth.client, payload.gym_id);
    if (!allowed) {
      return jsonResponse({ error: 'Unauthorized for this gym.' }, 403);
    }

    const mode = payload.mode ?? 'template';

    if (mode === 'quota') {
      const quota = await getAiQuota(auth.client, payload.gym_id);
      return jsonResponse({ success: true, quota }, 200);
    }

    if (mode === 'template') {
      const plan = generateFromTemplate({
        goal_key: payload.goal_key,
        dietary_preference: payload.dietary_preference,
        target_calories: payload.target_calories,
        member_weight_kg: payload.member_weight_kg,
        cuisine_hint: payload.cuisine_hint,
      });

      return jsonResponse({
        success: true,
        source: 'template',
        plan,
      }, 200);
    }

    if (mode === 'ai') {
      const plan = await generateWithOpenAi(auth.client, payload);
      const quota = await getAiQuota(auth.client, payload.gym_id);

      return jsonResponse({
        success: true,
        source: 'ai',
        plan,
        quota,
      }, 200);
    }

    return jsonResponse({ error: 'Invalid mode. Use template, ai, or quota.' }, 400);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unexpected error.' },
      500,
    );
  }
});
