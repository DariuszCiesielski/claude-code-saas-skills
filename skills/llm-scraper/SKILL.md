---
name: llm-scraper
description: Extract structured data from any webpage using LLM. TypeScript/Node.js library with Zod schemas, Playwright browser automation, and Vercel AI SDK integration. Works with OpenAI, Anthropic, Gemini, and local models via Ollama. Use when you need to scrape competitor pricing, analyze SERP, extract product catalogs, research leads, audit landing pages, or turn unstructured HTML into typed JSON. TRIGGER when user asks to "scrape", "extract from website", "analyze competitor site", "get structured data from URL", "benchmark konkurenta", "zrób audit SEO strony", or when the task requires running real browser against a webpage and extracting specific fields. Best paired with a local LLM (Qwen3.6, Mistral) for zero-cost scraping at scale. NOT for: search engines (use Brave/Exa), static content parsing (use cheerio), or simple text extraction (use markitdown).
---

# llm-scraper — structured web data extraction

Wrapper around `mishushakov/llm-scraper` for turning any webpage into typed JSON using an LLM. Battle-tested in production: used for SEO audits, competitor benchmarks, and lead enrichment.

## When to use this skill

- **Competitor analysis**: extract pricing, positioning, CTAs, tech stack from a competitor's landing page
- **SEO audits**: scrape target client sites, extract meta tags, H1-H6 hierarchy, schema.org, identify issues
- **Lead enrichment**: take a list of company URLs, extract industry, size signals, contact channels, decision makers
- **SERP analysis**: scrape top 10 results for a keyword, extract article structure, word count, FAQ presence
- **Product catalogs**: turn any e-commerce listing into a JSON array with name, price, category
- **Landing page CRO audits**: extract CTA count/position, form fields, social proof signals

## When NOT to use

- Simple text extraction from local files → use `markitdown` skill
- Search (finding URLs) → use Brave Search, Exa, or Google
- Static content parsing where you know the exact HTML structure → `cheerio` is faster
- Real-time data (stocks, scores) → use dedicated APIs

## Installation

```bash
npm install llm-scraper zod playwright
npx playwright install chromium

# LLM provider (pick one):
npm install ollama-ai-provider-v2      # local, zero cost
# OR
npm install @ai-sdk/openai             # cloud, ~$0.002/page
# OR
npm install @ai-sdk/google             # Gemini, cheaper than OpenAI
```

## Basic usage

```typescript
import { chromium } from 'playwright'
import { z } from 'zod'
import { Output } from 'ai'
import { ollama } from 'ollama-ai-provider-v2'
import LLMScraper from 'llm-scraper'

const browser = await chromium.launch({ headless: true })
const page = await browser.newPage()
await page.goto('https://example.com')

const llm = ollama('qwen3.6:35b-a3b')  // local, no cost
const scraper = new LLMScraper(llm)

const schema = z.object({
  title: z.string(),
  pricing: z.object({
    visible: z.boolean(),
    entryPrice: z.string().optional(),
  }),
  ctas: z.array(z.string()).max(5),
})

const { data } = await scraper.run(page, Output.object({ schema }), {
  format: 'html',   // or 'markdown' for cleaner input
})

console.log(data)
await browser.close()
```

## Production pattern — Next.js Server Action

```typescript
// src/app/api/audit/route.ts
import { auditSeo } from '@/lib/llm-scraper'

export async function POST(req: Request) {
  const { url } = await req.json()
  const result = await auditSeo(url)
  // Save to Supabase
  await supabase.from('audits').insert({ url, data: result })
  return Response.json(result)
}

// src/lib/llm-scraper.ts
export async function auditSeo(url: string) {
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage()
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 })

  const llm = process.env.OLLAMA_MODEL
    ? ollama(process.env.OLLAMA_MODEL, { baseURL: process.env.OLLAMA_URL })
    : google('gemini-2.5-flash')

  const scraper = new LLMScraper(llm)
  const schema = z.object({/* your fields */})
  const { data } = await scraper.run(page, Output.object({ schema }), { format: 'html' })
  await browser.close()
  return data
}
```

## Schema design tips

- **Use `.describe()` on Zod fields** — the LLM reads these as instructions
- **Group related fields into nested objects** — better grounding than flat schemas
- **Use `z.enum()` for bounded values** — prevents hallucinations
- **Max array length with `.max(N)`** — avoids over-extraction
- **Mark optional with `.optional()`** — LLM may not find every field

## Cost optimization

Per-page cost (approx.):

| LLM | Cost | Speed | Quality |
|-----|------|-------|---------|
| Ollama + Qwen3.6 local | **$0** | 60s | Good for PL, mid-complex schemas |
| Gemini 2.5 Flash | ~$0.001 | 8s | Excellent |
| OpenAI gpt-4o-mini | ~$0.002 | 10s | Excellent |
| Claude Haiku | ~$0.003 | 6s | Excellent |

For batch operations (100+ pages), Ollama + local model saves $50-300 vs cloud.

## Common gotchas

- **Playwright needs `chromium` downloaded** — run `npx playwright install chromium` after install
- **Vercel serverless limits**: Playwright + LLM call = likely >10s timeout on Hobby plan. Use Edge Functions or move to dedicated worker (Railway, Fly.io)
- **Some sites block headless**: add `--disable-blink-features=AutomationControlled` flag
- **Pagination**: extract per-page, don't try to scrape a list + all details in one call
- **Rate limits**: if the site has bot detection, add delay between requests and rotate user agents

## Real-world example: SEO audit pipeline

Used in production audits for 3 client leads (2026-04-17). Pattern:

1. Client gives URL
2. Playwright loads page
3. llm-scraper + Qwen3.6 local extracts: title, meta, H1-H6, schema, CTAs, content topics, UX issues
4. Output saved as JSON in Supabase
5. Second pass: Claude/Gemini generates human-readable audit report from JSON
6. PDF generated (Python `markdown` + Chrome headless) → sent to client

Result: 10-minute audit that would take 2-3h manually, at ~$0.01 cost (or zero with local model).

## References

- Repo: https://github.com/mishushakov/llm-scraper
- Vercel AI SDK: https://sdk.vercel.ai/
- Playwright: https://playwright.dev/
- Ollama provider: https://github.com/nordwestt/ollama-ai-provider-v2
