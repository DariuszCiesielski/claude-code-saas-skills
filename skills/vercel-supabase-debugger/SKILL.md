---
name: vercel-supabase-debugger
description: Diagnosing issues in the Vercel + Supabase stack — 500 on API route, edge function timeout, missing env vars, RLS blocking queries, CORS errors, auth loops. Use when something is broken, deploy failed, "500 error", "can't log in", "data not loading", "timeout", "CORS", "page won't open". Auto-activates on HTTP 4xx/5xx errors.
---

# Vercel + Supabase Debugger

Systematic diagnosis of issues in the Vercel + Supabase stack. Decision tree: symptom -> possible causes -> diagnostics -> fix.

## When to Use

- Something is broken: "500 error", "not loading", "timeout", "blank page"
- Deploy failed on Vercel
- Auth not working: "can't log in", "session expired", "redirect loop"
- Data not returning from database: "empty list", "undefined", "null"
- CORS errors in console
- On demand: "debug", "diagnose", "why isn't it working"

## When NOT to Use

- Problem is in a different stack (not Vercel + Supabase)
- Styling/CSS issue (that's design, not a bug)
- Feature request (wants new functionality, not a fix)

## Instructions

### Step 0: Gather Context

Before starting to debug, gather facts:

```bash
# Deploy status
vercel ls --limit 3 2>/dev/null

# Logs from latest deploy (if failed)
vercel logs $(vercel ls --limit 1 2>/dev/null | tail -1 | awk '{print $1}') 2>/dev/null | tail -50

# Env vars — are they configured
vercel env ls 2>/dev/null

# Git — what changed recently
git log --oneline -5
git diff --stat HEAD~1
```

### Step 1: Identify the Symptom

Use the decision tree:

```
Symptom?
├── Deploy failed → Section A
├── HTTP 500 → Section B
├── HTTP 401/403 → Section C
├── Timeout (504/408) → Section D
├── CORS error → Section E
├── Empty data (null/[]) → Section F
├── Auth loop / redirect → Section G
├── Page won't load (blank) → Section H
├── File upload fails → Section J
└── Other → Section I
```

---

### Section A: Deploy Failed

| Step | Check | Command |
|------|-------|---------|
| A1 | Build log — where does it fail? | `vercel logs <url> 2>&1 \| grep -i error` |
| A2 | TypeScript errors? | `npx tsc --noEmit` |
| A3 | Missing dependency? | Check if `package.json` has all imports |
| A4 | Node version mismatch? | `vercel.json` -> `"functions": { "runtime": "nodejs20.x" }` |
| A5 | Env var missing at build time? | Env vars with `NEXT_PUBLIC_` prefix must be available at build time |

**Most common cause:** TypeScript error or missing env var.

---

### Section B: HTTP 500

| Step | Check | Command |
|------|-------|---------|
| B1 | Runtime logs | `vercel logs <url> --follow` |
| B2 | Do env vars exist? | `vercel env ls` -> compare with `.env.local` |
| B3 | Supabase client init | Are `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` set? |
| B4 | Service role in client? | Search for `SUPABASE_SERVICE_ROLE` — NEVER in frontend code |
| B5 | Unhandled rejection | Search for `async` without `try/catch` in API routes |

**Most common cause:** Missing env vars on Vercel (present in `.env.local` but not in the dashboard).

**Quick fix:**
```bash
# Push local env vars to Vercel
cat .env.local | grep -v "^#" | while IFS='=' read -r key value; do
  vercel env add "$key" production <<< "$value"
done
```

---

### Section C: HTTP 401/403

| Step | Check |
|------|-------|
| C1 | Is the user logged in? -> `supabase.auth.getUser()` |
| C2 | Has the token expired? -> Check expiry in JWT |
| C3 | Is an RLS policy blocking? -> Check policies on the table |
| C4 | Is middleware/proxy blocking? -> Check `proxy.ts` / `middleware.ts` |
| C5 | ANON key vs SERVICE_ROLE | Anon key respects RLS, service role bypasses it |

**Diagnostic:**
```sql
-- Check RLS policies on a table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies WHERE tablename = 'TABLE_NAME';
```

---

### Section D: Timeout (504/408)

| Step | Check |
|------|-------|
| D1 | What type of function? | Serverless (max 60s free / 300s pro) vs Edge (max 30s) |
| D2 | N+1 query? | Loop with a DB query inside -> batch it |
| D3 | Large payload? | Response >4.5MB -> streaming or pagination |
| D4 | External API slow? | Timeout on 3rd party API -> add timeout + fallback |
| D5 | Cold start? | First request after deploy is slower |

**Quick fix:**
```typescript
// Add timeout to fetch
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 10000);
const res = await fetch(url, { signal: controller.signal });
clearTimeout(timeout);
```

---

### Section E: CORS Error

| Step | Check |
|------|-------|
| E1 | Is it a Route Handler? | Add CORS headers |
| E2 | Is the request cross-origin? | Localhost:3000 -> Supabase URL = cross-origin |
| E3 | Supabase CORS config | Dashboard -> Settings -> API -> check allowed origins |
| E4 | Preflight (OPTIONS) | Does the Route Handler handle OPTIONS? |

**Quick fix (Route Handler):**
```typescript
export async function OPTIONS() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
```

---

### Section F: Empty Data (null / [])

| Step | Check |
|------|-------|
| F1 | RLS enabled without policies? | `ENABLE RLS` + no policies = DENY ALL |
| F2 | FK type mismatch? | `uuid` vs `text` in join — no implicit cast |
| F3 | Filter too restrictive? | Remove `.eq()` and check if data returns |
| F4 | No data in table? | `SELECT count(*) FROM table_name` |
| F5 | Supabase client — anon vs service? | Anon respects RLS |

**Diagnostic:**
```sql
-- Check if RLS is blocking
SET role authenticated;
SET request.jwt.claim.sub = 'USER_UUID_HERE';
SELECT * FROM table_name LIMIT 5;
```

---

### Section G: Auth Loop / Redirect

| Step | Check |
|------|-------|
| G1 | Middleware/proxy config | Does it redirect a logged-in user back to login? |
| G2 | Callback URL | Is `NEXT_PUBLIC_SITE_URL` set correctly? |
| G3 | Cookies blocked | Are 3rd party cookies disabled in the browser? |
| G4 | Supabase Web Locks | `getSession()` never resolves? |
| G5 | Missing organization (Clerk) | `auth()` returns `{ orgSlug: null }` -> redirect loop |

**Quick diagnostic:**
```bash
# Check if callback URL is correct
grep -r "NEXT_PUBLIC_SITE_URL\|NEXTAUTH_URL\|CLERK" .env.local
```

---

### Section H: Blank Page / Won't Load

| Step | Check |
|------|-------|
| H1 | Browser console | Open DevTools -> Console -> look for red errors |
| H2 | Hydration mismatch? | Server HTML != Client HTML -> look for `useEffect` rendering different UI |
| H3 | Missing `'use client'` | Component with useState/useEffect without the directive |
| H4 | Infinite loop | useEffect without dependency array -> re-render loop |
| H5 | Loading state stuck | `isLoading` never transitions to `false` -> auth problem |

---

### Section I: Other Issues

If the symptom doesn't match A-H:

1. **Collect the exact error message** (full text, not a summary)
2. **Check git log** — what changed since the last working state
3. **Compare local vs deploy** — `diff .env.local <(vercel env pull --environment=production 2>/dev/null)`
4. **Isolate the problem** — comment out recent changes and check if the base code works

### Step 2: Diagnostic Report

```markdown
## Diagnosis — [date]

**Symptom:** [what the user sees]
**Section:** [A-I]
**Cause:** [identified cause]

### Diagnostics performed:
1. [What I checked] -> [result]
2. [What I checked] -> [result]

### Fix:
[Description of solution + code]

### Prevention:
[How to avoid this problem in the future]
```

---

### Section J: File Upload / Storage

| Step | Check |
|------|-------|
| J1 | Does the bucket exist? | `curl -H "apikey: $KEY" https://PROJECT.supabase.co/storage/v1/bucket/BUCKET` |
| J2 | Is the bucket public? | `"public": false` -> `getPublicUrl()` returns a URL but the file is inaccessible |
| J3 | Non-ASCII characters in filename? | Supabase Storage rejects diacritics and special characters in paths |
| J4 | Server Action with file -> 400? | Server Actions with FormData+file often fail on Vercel — use an API Route |
| J5 | Body size limit? | Vercel serverless: ~4.5MB body. Multiple files at once -> process sequentially one at a time |
| J6 | Service role for upload? | `anon` key respects RLS on Storage — use `service_role` key for uploads |

**Confirmed solutions:**

1. **Server Action with file -> 400 on Vercel:** Replace `uploadReference(formData)` (server action) with `fetch("/api/references/upload", { body: formData })` (API route). Server actions with FormData containing File are unstable on Vercel serverless.

2. **Non-ASCII characters in Storage path:** `file.name.replace(/[^a-zA-Z0-9._-]/g, "_")` — sanitize BEFORE upload. Original name preserved in database (`file_name` column).

3. **Multiple files at once:** Process sequentially (1 request per file) instead of one FormData with multiple files. Prevents exceeding body limit and enables progress bar (X/N).

4. **PDF parsing in serverless:** `pdf-parse` (pdfjs-dist) requires DOMMatrix and other browser APIs — doesn't work on Vercel. Use `unpdf` (WASM, serverless-compatible) + Mistral OCR (`mistral-ocr-latest`) for scans + LlamaParse as fallback.

5. **Bucket must be public:** If using `getPublicUrl()`, the bucket must have `"public": true`. Set with: `curl -X PUT .../storage/v1/bucket/BUCKET -d '{"public": true}'` using service_role key.

---

## Pitfalls

### Fixing symptoms instead of root causes
**Symptom**: Agent adds try/catch that hides the error instead of fixing it
**Cause**: Easier to hide than to diagnose
**Solution**: ALWAYS identify ROOT CAUSE. try/catch is a last resort, not the first line of defense.

### Env vars — local vs production
**Symptom**: "It works on my machine" — locally OK, 500 on Vercel
**Cause**: `.env.local` has vars, Vercel Dashboard doesn't
**Solution**: FIRST diagnostic step: `vercel env ls` -> compare with `.env.local`.

### Debugging on production
**Symptom**: Agent adds console.log to production to see what's happening
**Cause**: No local debugging environment
**Solution**: Use `vercel logs` instead of adding console.log. Reproduce the problem locally.

### RLS — "let's disable it so it works"
**Symptom**: Agent suggests `ALTER TABLE ... DISABLE ROW LEVEL SECURITY`
**Cause**: RLS blocks queries, agent wants a quick fix
**Solution**: NEVER disable RLS. Instead: write a proper policy. If debugging -> use service_role ONLY in Server Actions.

### Skipping middleware/proxy
**Symptom**: Diagnosis skips middleware — focuses on the component
**Cause**: Request never reaches the component because middleware redirects
**Solution**: Check `proxy.ts` / `middleware.ts` BEFORE debugging the page.

### Supabase client re-creation
**Symptom**: Auth state unstable, session gets lost
**Cause**: `createBrowserClient()` called on every render instead of once
**Solution**: Supabase client should be a singleton — created once and shared.
