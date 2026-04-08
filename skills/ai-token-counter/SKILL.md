---
name: ai-token-counter
description: Global AI token counter — Vercel AI SDK wrapper logging usage to Supabase per project/model/operation
triggers:
  - "add token counter"
  - "monitor AI usage"
  - "token counter"
  - "log tokens"
  - "how many tokens does it use"
---

# AI Token Counter

Lightweight wrapper for Vercel AI SDK (`generateText`, `streamText`) + fire-and-forget token usage logging to Supabase.

## When to Use
- When adding a new AI call in a project
- When onboarding a project to your ecosystem (cross-project cost tracking)
- When you want to know how many tokens each project/model/operation consumes

## Architecture

```
Your code -> trackedGenerateText() -> AI SDK -> OpenAI/Anthropic/Gemini
                | (fire-and-forget)
           Supabase: ai_usage_log
                | (cron/dashboard)
           Cost Monitor: /costs
```

## Step 1: Supabase Migration (once per Supabase project)

```sql
-- AI token usage log table
CREATE TABLE IF NOT EXISTS ai_usage_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_slug text NOT NULL,        -- e.g., 'lead-generator', 'my-saas'
  operation text NOT NULL,            -- e.g., 'chat', 'embedding', 'content-generation'
  model text NOT NULL,                -- e.g., 'gpt-4o', 'claude-sonnet-4'
  provider text NOT NULL DEFAULT 'openai', -- 'openai', 'anthropic', 'google'
  input_tokens integer NOT NULL DEFAULT 0,
  output_tokens integer NOT NULL DEFAULT 0,
  total_tokens integer NOT NULL DEFAULT 0,
  cost_usd numeric(10,6),            -- optional cost in USD
  duration_ms integer,               -- call duration
  endpoint text,                     -- e.g., '/api/chat', 'edge-function:generate-article'
  metadata jsonb,                    -- arbitrary additional data
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for dashboard queries
CREATE INDEX idx_ai_usage_project ON ai_usage_log(project_slug, created_at DESC);
CREATE INDEX idx_ai_usage_model ON ai_usage_log(model, created_at DESC);
CREATE INDEX idx_ai_usage_daily ON ai_usage_log(created_at DESC);

-- RLS: only service_role can write, admin can read
ALTER TABLE ai_usage_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access" ON ai_usage_log
  FOR ALL USING (true) WITH CHECK (true);

-- Aggregate view per day/project/model (for dashboard)
CREATE OR REPLACE VIEW ai_usage_daily AS
SELECT
  date_trunc('day', created_at)::date AS day,
  project_slug,
  provider,
  model,
  count(*) AS requests,
  sum(input_tokens) AS input_tokens,
  sum(output_tokens) AS output_tokens,
  sum(total_tokens) AS total_tokens,
  sum(cost_usd) AS cost_usd
FROM ai_usage_log
GROUP BY 1, 2, 3, 4
ORDER BY 1 DESC, 5 DESC;
```

## Step 2: File `src/lib/ai/usage-tracker.ts`

```typescript
/**
 * AI Usage Tracker — fire-and-forget token logging.
 *
 * Wrapper for AI SDK generateText/streamText with automatic
 * token usage logging to the ai_usage_log table.
 *
 * RULE: Logging errors NEVER interrupt business operations.
 */

import { generateText, streamText, type GenerateTextResult, type StreamTextResult } from 'ai';
import { createClient } from '@supabase/supabase-js';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const PROJECT_SLUG = process.env.PROJECT_SLUG || 'unknown';
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || '';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// Pricing per 1M tokens (USD) — update when prices change
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  // OpenAI
  'gpt-4o':       { input: 2.50,  output: 10.00 },
  'gpt-4o-mini':  { input: 0.15,  output: 0.60 },
  'gpt-4.1':      { input: 2.00,  output: 8.00 },
  'gpt-4.1-mini': { input: 0.40,  output: 1.60 },
  // Anthropic
  'claude-opus-4':   { input: 15.00, output: 75.00 },
  'claude-sonnet-4': { input: 3.00,  output: 15.00 },
  'claude-haiku-3.5':{ input: 0.80,  output: 4.00 },
  // Google
  'gemini-2.5-pro':   { input: 1.25, output: 10.00 },
  'gemini-2.5-flash': { input: 0.15, output: 0.60 },
};

// ---------------------------------------------------------------------------
// Supabase client (lazy singleton)
// ---------------------------------------------------------------------------

let _client: ReturnType<typeof createClient> | null = null;

function getServiceClient() {
  if (!_client && SUPABASE_URL && SUPABASE_SERVICE_KEY) {
    _client = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  }
  return _client;
}

// ---------------------------------------------------------------------------
// Cost calculation
// ---------------------------------------------------------------------------

function computeCost(model: string, inputTokens: number, outputTokens: number): number | null {
  // Look for exact match or prefix match (e.g., full ID with date matches base key)
  const pricing = MODEL_PRICING[model]
    || Object.entries(MODEL_PRICING).find(([key]) => model.startsWith(key))?.[1];

  if (!pricing) return null;

  return (inputTokens / 1_000_000) * pricing.input
       + (outputTokens / 1_000_000) * pricing.output;
}

// ---------------------------------------------------------------------------
// Fire-and-forget logger
// ---------------------------------------------------------------------------

interface LogParams {
  operation: string;
  model: string;
  provider?: string;
  inputTokens: number;
  outputTokens: number;
  durationMs?: number;
  endpoint?: string;
  metadata?: Record<string, unknown>;
}

async function logUsage(params: LogParams): Promise<void> {
  try {
    const client = getServiceClient();
    if (!client) return; // no config = silent skip

    const totalTokens = params.inputTokens + params.outputTokens;
    const costUsd = computeCost(params.model, params.inputTokens, params.outputTokens);

    await client.from('ai_usage_log').insert({
      project_slug: PROJECT_SLUG,
      operation: params.operation,
      model: params.model,
      provider: params.provider || detectProvider(params.model),
      input_tokens: params.inputTokens,
      output_tokens: params.outputTokens,
      total_tokens: totalTokens,
      cost_usd: costUsd,
      duration_ms: params.durationMs,
      endpoint: params.endpoint,
      metadata: params.metadata,
    });
  } catch (error) {
    console.error('[ai-usage] Failed to log:', error);
    // Fire-and-forget — NEVER throw
  }
}

function detectProvider(model: string): string {
  if (model.startsWith('gpt-') || model.startsWith('o1') || model.startsWith('o3') || model.startsWith('o4')) return 'openai';
  if (model.includes('claude')) return 'anthropic';
  if (model.startsWith('gemini-')) return 'google';
  if (model.startsWith('llama-')) return 'meta';
  if (model.startsWith('deepseek-')) return 'deepseek';
  return 'unknown';
}

// ---------------------------------------------------------------------------
// Tracked wrappers
// ---------------------------------------------------------------------------

type GenerateTextParams = Parameters<typeof generateText>[0];
type StreamTextParams = Parameters<typeof streamText>[0];

interface TrackingOptions {
  operation: string;
  endpoint?: string;
  metadata?: Record<string, unknown>;
}

/**
 * Wrapper for AI SDK `generateText` with automatic token logging.
 *
 * @example
 * const result = await trackedGenerateText({
 *   model: openai('gpt-4o'),
 *   prompt: 'Write an article...',
 * }, { operation: 'article-generation', endpoint: '/api/generate' });
 */
export async function trackedGenerateText(
  params: GenerateTextParams,
  tracking: TrackingOptions,
): Promise<GenerateTextResult<any, any>> {
  const start = Date.now();
  const result = await generateText(params);
  const duration = Date.now() - start;

  const usage = result.usage;
  if (usage) {
    // Don't block — log in background
    logUsage({
      operation: tracking.operation,
      model: result.response?.modelId || String(params.model) || 'unknown',
      inputTokens: usage.promptTokens,
      outputTokens: usage.completionTokens,
      durationMs: duration,
      endpoint: tracking.endpoint,
      metadata: tracking.metadata,
    });
  }

  return result;
}

/**
 * Wrapper for AI SDK `streamText` — logs after stream completion.
 *
 * @example
 * const result = trackedStreamText({
 *   model: openai('gpt-4o'),
 *   prompt: 'Answer the question...',
 * }, { operation: 'chat', endpoint: '/api/chat' });
 *
 * // Use normally: result.textStream, result.toDataStreamResponse(), etc.
 * // Tokens will be logged automatically after the stream ends.
 */
export function trackedStreamText(
  params: StreamTextParams,
  tracking: TrackingOptions,
): StreamTextResult<any, any> {
  const start = Date.now();
  const result = streamText(params);

  // Log after stream ends (non-blocking)
  result.usage.then((usage) => {
    const duration = Date.now() - start;
    result.response.then((response) => {
      logUsage({
        operation: tracking.operation,
        model: response.modelId || String(params.model) || 'unknown',
        inputTokens: usage.promptTokens,
        outputTokens: usage.completionTokens,
        durationMs: duration,
        endpoint: tracking.endpoint,
        metadata: tracking.metadata,
      });
    }).catch(() => {});
  }).catch(() => {});

  return result;
}

// ---------------------------------------------------------------------------
// Manual logging (for Supabase Edge Functions, direct API calls)
// ---------------------------------------------------------------------------

/**
 * Manual usage logging — for code that doesn't use AI SDK.
 *
 * @example
 * // After calling OpenAI API directly:
 * const response = await openai.chat.completions.create({ ... });
 * logAiUsage({
 *   operation: 'expert-article',
 *   model: 'gpt-4o',
 *   inputTokens: response.usage.prompt_tokens,
 *   outputTokens: response.usage.completion_tokens,
 *   endpoint: 'edge-function:generate-article',
 * });
 */
export { logUsage as logAiUsage };
```

## Step 3: Add `PROJECT_SLUG` to `.env.local`

```bash
# .env.local
PROJECT_SLUG=my-saas-app   # unique project name
```

## Step 4: Replace calls in your code

### Before (without tracking):
```typescript
import { generateText } from 'ai';
import { openai } from '@ai-sdk/openai';

const result = await generateText({
  model: openai('gpt-4o'),
  prompt: 'Write an article...',
});
```

### After (with tracking):
```typescript
import { trackedGenerateText } from '@/lib/ai/usage-tracker';
import { openai } from '@ai-sdk/openai';

const result = await trackedGenerateText({
  model: openai('gpt-4o'),
  prompt: 'Write an article...',
}, { operation: 'article-generation', endpoint: '/api/generate' });
```

**The change is 2 lines:** import + adding a second argument with operation description.

## Step 5: Cost Monitor View (optional)

Add an aggregation query to your dashboard:

```sql
-- Top 10 costs per project (last 30 days)
SELECT
  project_slug,
  provider,
  sum(total_tokens) as tokens,
  sum(cost_usd)::numeric(10,4) as cost_usd,
  count(*) as requests
FROM ai_usage_log
WHERE created_at > now() - interval '30 days'
GROUP BY 1, 2
ORDER BY cost_usd DESC
LIMIT 10;
```

## For Supabase Edge Functions (Deno)

Edge Functions don't use AI SDK — use `logAiUsage` manually:

```typescript
// In Edge Function (Deno)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

async function logUsageEF(params: {
  projectSlug: string;
  operation: string;
  model: string;
  provider: string;
  inputTokens: number;
  outputTokens: number;
  costUsd?: number;
}) {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    await supabase.from('ai_usage_log').insert({
      project_slug: params.projectSlug,
      operation: params.operation,
      model: params.model,
      provider: params.provider,
      input_tokens: params.inputTokens,
      output_tokens: params.outputTokens,
      total_tokens: params.inputTokens + params.outputTokens,
      cost_usd: params.costUsd,
    });
  } catch (e) {
    console.error('[usage] log failed:', e);
  }
}
```

## Deployment Order

1. **Central Supabase** — SQL migration + ai_usage_log table
2. **Existing projects with AI calls** — replace current usage tracking with ai_usage_log (unification)
3. **New projects** — add wrapper from the start
4. **Remaining projects** — incrementally during each session

## Notes
- **Fire-and-forget** — logging NEVER blocks and NEVER throws exceptions
- **Lazy client** — Supabase client created only on first log call
- **No config = silent skip** — if env vars are missing, wrapper works like regular AI SDK
- **Built-in pricing** — `MODEL_PRICING` requires manual updates every ~3 months
- The `ai_usage_log` table should be in a **central Supabase project** — one dashboard for the entire ecosystem
