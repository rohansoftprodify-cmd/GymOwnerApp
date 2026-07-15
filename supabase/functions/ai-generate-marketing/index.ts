import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import {
  generateFromTemplate,
  type MarketingContentType,
  type MarketingResult,
} from './marketing_templates.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const DEFAULT_MONTHLY_AI_LIMIT = 10;

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function getAuthenticatedGymClient(req: Request): Promise<{
  client: SupabaseClient;
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

  return { client };
}

async function assertGymStaff(client: SupabaseClient, gymId: string): Promise<boolean> {
  const { data, error } = await client.rpc('current_user_is_gym_member', {
    target_gym_id: gymId,
  });
  if (error) return false;
  return Boolean(data);
}

function monthlyAiLimit(): number {
  const raw = Deno.env.get('MARKETING_AI_MONTHLY_LIMIT');
  const parsed = raw ? Number.parseInt(raw, 10) : DEFAULT_MONTHLY_AI_LIMIT;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_MONTHLY_AI_LIMIT;
}

type GenerateMarketingPayload = {
  gym_id: string;
  content_type: MarketingContentType;
  prompt: string;
  mode?: 'template' | 'ai';
  offer_hint?: string;
  member_name?: string;
};

async function fetchGymName(client: SupabaseClient, gymId: string): Promise<string> {
  const { data } = await client.from('gyms').select('name').eq('id', gymId).maybeSingle();
  return (data?.name as string | undefined) ?? 'Your Gym';
}

async function generateWithOpenAi(input: {
  gymName: string;
  contentType: MarketingContentType;
  prompt: string;
  offerHint?: string;
  memberName?: string;
}): Promise<MarketingResult> {
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured. Use template mode or set the secret.');
  }

  const system = `You are a gym marketing copywriter for Indian fitness businesses.
Return ONLY valid JSON with keys:
title, body, instagram_caption, push_notification (object with title, body), hashtags (string array), cta, festival_label.
Keep copy punchy, local, and action-oriented. Use emojis sparingly for Instagram.`;

  const user = JSON.stringify({
    gym_name: input.gymName,
    content_type: input.contentType,
    user_prompt: input.prompt,
    offer_hint: input.offerHint ?? null,
    member_name: input.memberName ?? null,
  });

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-4o-mini',
      temperature: 0.8,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI request failed: ${text}`);
  }

  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (!content) throw new Error('Empty AI response.');

  const parsed = JSON.parse(content);
  return {
    mode: 'template',
    content_type: input.contentType,
    festival_key: 'ai',
    festival_label: parsed.festival_label ?? 'Custom',
    title: parsed.title ?? `${input.gymName} Marketing`,
    body: parsed.body ?? parsed.instagram_caption ?? '',
    instagram_caption: parsed.instagram_caption ?? parsed.body ?? '',
    push_notification: {
      title: parsed.push_notification?.title ?? `Offer at ${input.gymName}`,
      body: parsed.push_notification?.body ?? parsed.body ?? '',
    },
    hashtags: Array.isArray(parsed.hashtags) ? parsed.hashtags.map(String) : [],
    cta: parsed.cta ?? 'Visit the gym today',
    prompt_used: input.prompt,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed.' }, 405);
  }

  const authResult = await getAuthenticatedGymClient(req);
  if (authResult instanceof Response) return authResult;
  const { client } = authResult;

  let body: GenerateMarketingPayload;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body.' }, 400);
  }

  const gymId = body.gym_id;
  const contentType = body.content_type;
  const prompt = body.prompt?.trim();

  if (!gymId || !contentType || !prompt) {
    return jsonResponse({ error: 'gym_id, content_type, and prompt are required.' }, 400);
  }

  if (!(await assertGymStaff(client, gymId))) {
    return jsonResponse({ error: 'Unauthorized for this gym.' }, 403);
  }

  const gymName = await fetchGymName(client, gymId);
  const mode = body.mode ?? 'template';

  if (mode === 'template') {
    const result = generateFromTemplate({
      contentType,
      gymName,
      prompt,
      offerHint: body.offer_hint,
      memberName: body.member_name,
    });
    return jsonResponse({ ...result, mode: 'template' }, 200);
  }

  const limit = monthlyAiLimit();
  const quota = await client.rpc('consume_gym_ai_marketing_quota', {
    p_gym_id: gymId,
    p_monthly_limit: limit,
  });

  const quotaData = quota.data as Record<string, unknown> | null;
  if (quota.error) {
    return jsonResponse({ error: quota.error.message }, 500);
  }
  if (quotaData && quotaData.allowed === false) {
    return jsonResponse(
      {
        error: `AI marketing quota exceeded (${quotaData.used}/${quotaData.limit} this month). Use template mode.`,
        quota: quotaData,
      },
      429,
    );
  }

  try {
    const result = await generateWithOpenAi({
      gymName,
      contentType,
      prompt,
      offerHint: body.offer_hint,
      memberName: body.member_name,
    });
    return jsonResponse({ ...result, mode: 'ai', quota: quotaData }, 200);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'AI generation failed.' },
      500,
    );
  }
});
