---
name: agent-hierarchy
description: >
  Defines agent roles and domain boundaries for SaaS projects (Next.js + Supabase).
  5 roles: Architect, Frontend Dev, Backend Dev, DevOps, QA — each with file scope,
  domain knowledge, and escalation rules. Use when working on a complex project
  with multiple layers, needing code review from a specific role's perspective,
  or delegating tasks to sub-agents. Trigger when user says
  "review as architect", "check backend", "evaluate from QA perspective",
  "delegate to", "review from perspective", "who should handle this".
  DO NOT use for simple, one-line changes — overhead > value.
---

## Roles and Scope

| Role | Model | File Scope | Related Skills |
|------|-------|------------|----------------|
| Architect | Opus | All (read-only) + CLAUDE.md, next.config.*, package.json | — |
| Frontend Dev | Sonnet | src/components/, src/app/**/page.tsx, src/app/**/layout.tsx, src/styles/ | design-system-themes, design-system-components, design-system-checklist |
| Backend Dev | Sonnet | src/app/api/, src/lib/, supabase/, src/actions/ | — |
| DevOps | Sonnet | .github/, vercel.json, supabase/migrations/, scripts/, .env.example | — |
| QA | Haiku | src/__tests__/, e2e/, playwright.config.* | — |

See `references/{role}.md` for details on each role.

## Delegation Rules

1. **Vertical:** Architect delegates to Frontend/Backend/DevOps/QA. Never the reverse — if Frontend Dev needs an architectural change, escalate to Architect.
2. **Horizontal:** Frontend Dev and Backend Dev can consult (API shape), but must NOT modify each other's files.
3. **Conflicts:** A change requiring edits in two domains (e.g., new endpoint + new component) = Architect coordinates.
4. **Boundaries:** An agent must NOT modify files outside its scope without explicit delegation. If it must — report to the user.

## Collaboration Protocol

ONLY for architectural and cross-domain changes (NOT for simple tasks):

1. **Confirm** — "I understand you want X. Is that correct?"
2. **Show options** — "I see 2-3 approaches: Option A: ... Option B: ..."
3. **User decides** — Wait for selection
4. **Show draft** — Key changes before saving
5. **User approves** — Save after acceptance

## When to Apply the Protocol

- Changes to package.json (new dependencies)
- Changes to next.config.* or vercel.json
- New/changed database schemas
- Changes to auth/RLS
- Supabase migrations

## When NOT to Apply

- Simple changes in a single file (add a button, fix text)
- Bug fix in a single domain
- CSS/Tailwind style adjustments

## How to Delegate to a Sub-Agent

```bash
# Example: review from Backend Dev perspective
claude --model sonnet --system-prompt "$(cat ~/.claude/skills/agent-hierarchy/references/backend-dev.md)" \
  -p "Review this file from the Backend Dev perspective: src/app/api/users/route.ts"
```

Or in an interactive session — say: "Read references/backend-dev.md and review this code from that perspective."

## 3 Levels of Orchestration

| Level | When | Tool | Skill |
|-------|------|------|-------|
| **Solo** | Simple tasks 1-3 files, bug fixes | Claude Code (Opus) | — |
| **Second agent** | Simple, isolated tasks to delegate | Any secondary model | — |
| **AI Crew** | Complex features 4+ files, design + arch + review | Pipeline of 6-8 roles | — |

**Rule:** Start with "Solo". Escalate to a second agent when you have simple parallel tasks. Escalate to Crew when scope requires multiple perspectives (design, architecture, code review, audit).

## Pitfalls

- DO NOT create 48 agents — 5 roles is the optimum for a solo developer with a SaaS portfolio
- DO NOT delegate simple one-line tasks — coordination overhead > execution time
- DO NOT force the 5-step protocol on everything — it will slow down the workflow
- Architect ALWAYS reviews: changes to package.json, next.config.*, database schemas, auth configuration
- If unsure which role — start with Architect (has the full picture)
