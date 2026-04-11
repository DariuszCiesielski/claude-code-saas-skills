<div align="center">

# Claude Code SaaS Skills

**Battle-tested agent skills for building SaaS products with Claude Code.**

![Skills](https://img.shields.io/badge/Skills-15-orange.svg)
![Language](https://img.shields.io/badge/Language-EN-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Claude Code](https://img.shields.io/badge/Claude%20Code-%E2%9C%93-blueviolet.svg)

</div>

---

## Why this matters

These aren't generic templates. Each skill encodes a **real pattern extracted from building 15+ SaaS products** — the kind of knowledge that normally takes months to accumulate.

- **Auth that actually works** — multi-tenant RLS, admin roles without recursion, credential vaults
- **Growth on autopilot** — AARRR funnels, programmatic SEO, cold outreach sequences
- **Design consistency** — 6 themes, CSS variables, component tokens, implementation checklists
- **Security by default** — three-perspective audits, OWASP checks, data exposure scans
- **Debug in minutes** — systematic Vercel + Supabase debugging trees, not guesswork

> One skill can save you a full day of trial-and-error. Fifteen skills change how you build.

---

## Quick start — 1 command

```bash
curl -fsSL https://raw.githubusercontent.com/DariuszCiesielski/claude-code-saas-skills/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/DariuszCiesielski/claude-code-saas-skills.git
cd claude-code-saas-skills
./install.sh
```

---

## All skills

| # | Skill | What it does | Example use |
|---|-------|-------------|-------------|
| 1 | **supabase-auth-multi-tenant** | Organization-scoped auth with RLS — the B2B SaaS pattern | "Add multi-tenant auth to my app" |
| 2 | **supabase-auth-admin-roles** | Admin/user role separation without RLS recursion | "Set up admin panel access" |
| 3 | **credentials-vault** | Secure per-project credential management | "Store API keys safely" |
| 4 | **fullstack-guardian** | Three-perspective security design (frontend/backend/auth) | "Review my app's security architecture" |
| 5 | **security-reviewer** | Security audit checklist (OWASP, auth flows, data exposure) | "Audit this codebase for vulnerabilities" |
| 6 | **growth-lead** | Virtual Head of Growth — AARRR funnel, OKR planning, channel selection | "Create a growth strategy for Q2" |
| 7 | **analytics-tracking** | Complete GA4 + GTM setup for SaaS (events, UTM, conversions) | "Set up analytics tracking" |
| 8 | **programmatic-seo** | SEO at scale — template pages for "[service] + [city]" patterns | "Generate 500 landing pages" |
| 9 | **cold-email** | Outbound sales sequences with personalization tiers | "Write a cold email sequence" |
| 10 | **design-system-themes** | Multi-theme implementation (6 themes, CSS variables, React Context) | "Add dark mode and theme switcher" |
| 11 | **design-system-components** | Unified design tokens (spacing, shadows, typography) | "Normalize my design tokens" |
| 12 | **design-system-checklist** | Implementation pipeline: audit → normalize → polish | "Audit my UI consistency" |
| 13 | **agent-hierarchy** | Multi-agent orchestration (5 roles, domain boundaries, delegation) | "Set up agent team for my project" |
| 14 | **ai-token-counter** | AI API cost tracking with fire-and-forget logging | "Track my AI token spend" |
| 15 | **vercel-supabase-debugger** | Systematic debugging tree for Vercel + Supabase production issues | "My API route returns 500" |

---

## How skills work

Drop a skill into `~/.claude/skills/` and Claude Code **automatically uses it** when it detects a matching trigger phrase.

```
~/.claude/skills/
├── growth-lead/
│   └── SKILL.md          ← activates when you say "growth strategy"
├── supabase-auth-multi-tenant/
│   └── SKILL.md          ← activates when you say "add organizations"
└── ...
```

Each skill contains: **triggers**, **step-by-step instructions**, **code examples**, and **pitfalls to avoid**.

---

## Stack assumptions

These skills assume a modern SaaS stack:

- **Frontend:** React 18+ / Next.js 14+ (App Router)
- **Backend:** Supabase (PostgreSQL + Auth + RLS + Edge Functions)
- **Hosting:** Vercel
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **Language:** TypeScript

Most patterns are universal — adapt to your stack as needed.

---

## Want more?

- **Need a custom AI solution for your business?** [Get in touch](https://aiwbiznesie.online/kontakt/)
- **Read about AI in business** at [aiwbiznesie.online](https://aiwbiznesie.online)

---

## License

MIT — use these skills however you want.

---

<div align="center">

Built by [AI w Biznesie](https://aiwbiznesie.online)

</div>
