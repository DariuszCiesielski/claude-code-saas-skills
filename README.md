# Claude Code SaaS Skills

A curated collection of **Agent Skills** for [Claude Code](https://claude.ai/claude-code) — purpose-built for SaaS founders, indie hackers, and small teams building products with modern stacks (Next.js, Supabase, Vercel, Tailwind).

These skills encode real-world patterns extracted from building 15+ SaaS products. They're not generic templates — each one solves a specific, recurring problem.

## What are Agent Skills?

Agent Skills are reusable instruction sets that extend Claude Code's capabilities. Drop a skill into `~/.claude/skills/` and Claude automatically uses it when relevant.

```
~/.claude/skills/
├── growth-lead/
│   └── SKILL.md          ← Claude reads this when you say "growth strategy"
├── supabase-auth-multi-tenant/
│   └── SKILL.md          ← Claude reads this when you say "add organizations"
└── ...
```

## Installation

**Single skill:**
```bash
mkdir -p ~/.claude/skills/growth-lead
cp skills/growth-lead/SKILL.md ~/.claude/skills/growth-lead/
```

**All skills:**
```bash
cp -r skills/* ~/.claude/skills/
```

## Skills

### 🏗️ Architecture & Auth

| Skill | What it does |
|-------|-------------|
| [supabase-auth-multi-tenant](skills/supabase-auth-multi-tenant/) | Organization-scoped auth with RLS — the B2B SaaS pattern |
| [supabase-auth-admin-roles](skills/supabase-auth-admin-roles/) | Admin/user role separation without RLS recursion |
| [credentials-vault](skills/credentials-vault/) | Secure per-project credential management |
| [fullstack-guardian](skills/fullstack-guardian/) | Three-perspective security design (frontend/backend/auth) |
| [security-reviewer](skills/security-reviewer/) | Security audit checklist (OWASP, auth flows, data exposure) |

### 📈 Growth & Marketing

| Skill | What it does |
|-------|-------------|
| [growth-lead](skills/growth-lead/) | Virtual Head of Growth — AARRR funnel, OKR planning, channel selection |
| [analytics-tracking](skills/analytics-tracking/) | Complete GA4 + GTM setup for SaaS (events, UTM, conversions) |
| [programmatic-seo](skills/programmatic-seo/) | SEO at scale — template pages for "[service] + [city]" patterns |
| [cold-email](skills/cold-email/) | Outbound sales sequences with personalization tiers |

### 🎨 Design System

| Skill | What it does |
|-------|-------------|
| [design-system-themes](skills/design-system-themes/) | Multi-theme implementation (6 themes, CSS variables, React Context) |
| [design-system-components](skills/design-system-components/) | Unified design tokens (spacing, shadows, typography) |
| [design-system-checklist](skills/design-system-checklist/) | Implementation pipeline: audit → normalize → polish |

### 🤖 AI & Orchestration

| Skill | What it does |
|-------|-------------|
| [agent-hierarchy](skills/agent-hierarchy/) | Multi-agent orchestration (5 roles, domain boundaries, delegation) |
| [ai-token-counter](skills/ai-token-counter/) | AI API cost tracking with fire-and-forget logging |

### 🔧 DevOps

| Skill | What it does |
|-------|-------------|
| [vercel-supabase-debugger](skills/vercel-supabase-debugger/) | Systematic debugging tree for Vercel + Supabase production issues |

## How skills work

Each skill has:
- **Triggers** — phrases that activate it ("add multi-tenant auth", "growth strategy")
- **Dependencies** — other skills it works with
- **Instructions** — step-by-step implementation guide
- **Examples** — code snippets and templates
- **Pitfalls** — common mistakes to avoid

Claude reads the skill when it detects a matching trigger and follows the instructions automatically.

## Stack assumptions

These skills assume a modern SaaS stack:
- **Frontend:** React 18+ / Next.js 14+ with App Router
- **Backend:** Supabase (PostgreSQL + Auth + RLS + Edge Functions)
- **Hosting:** Vercel (Fluid Compute)
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **Language:** TypeScript

Most skills adapt to other stacks — the patterns are universal even if examples use specific tools.

## Contributing

Found a bug? Have an improvement? PRs welcome.

When submitting a skill:
1. Follow the SKILL.md format (frontmatter + triggers + instructions + examples + pitfalls)
2. Keep it self-contained (no private infrastructure dependencies)
3. Include real-world examples, not toy code
4. Add a "Pitfalls" section — that's where the real value is

## License

MIT — use these skills however you want.

---

Built by [@DariuszCiesielski](https://github.com/DariuszCiesielski) • Extracted from building 15+ SaaS products with Claude Code
