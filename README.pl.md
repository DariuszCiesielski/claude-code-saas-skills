🇬🇧 [English](README.md) | 🇵🇱 [Polski](README.pl.md)

![Last updated](https://img.shields.io/badge/Last%20updated-April%202026-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Skills](https://img.shields.io/badge/Skills-15-orange.svg)

# Claude Code SaaS Skills

Wyselekcjonowana kolekcja **Agent Skills** dla [Claude Code](https://claude.ai/claude-code) — stworzona dla founderów SaaS, indie hackerów i małych zespołów budujących produkty na nowoczesnym stacku (Next.js, Supabase, Vercel, Tailwind).

Te skille kodują sprawdzone wzorce wyciągnięte z budowania 15+ produktów SaaS. To nie są generyczne szablony — każdy rozwiązuje konkretny, powtarzający się problem.

## Czym są Agent Skills?

Agent Skills to zestawy instrukcji, które rozszerzają możliwości Claude Code. Wrzuć skill do `~/.claude/skills/` i Claude automatycznie go używa, gdy rozpozna pasujący kontekst.

```
~/.claude/skills/
├── growth-lead/
│   └── SKILL.md          ← Claude czyta to gdy powiesz "strategia wzrostu"
├── supabase-auth-multi-tenant/
│   └── SKILL.md          ← Claude czyta to gdy powiesz "dodaj organizacje"
└── ...
```

## Instalacja

**Pojedynczy skill:**
```bash
mkdir -p ~/.claude/skills/growth-lead
cp skills/growth-lead/SKILL.md ~/.claude/skills/growth-lead/
```

**Wszystkie skille:**
```bash
cp -r skills/* ~/.claude/skills/
```

## Skille

### 🏗️ Architektura i Auth

| Skill | Co robi |
|-------|---------|
| [supabase-auth-multi-tenant](skills/supabase-auth-multi-tenant/) | Auth z organizacjami i RLS — wzorzec B2B SaaS |
| [supabase-auth-admin-roles](skills/supabase-auth-admin-roles/) | Separacja ról admin/user bez rekurencji RLS |
| [credentials-vault](skills/credentials-vault/) | Bezpieczne zarządzanie kluczami per projekt |
| [fullstack-guardian](skills/fullstack-guardian/) | Trzyperspektywowe projektowanie bezpieczeństwa (frontend/backend/auth) |
| [security-reviewer](skills/security-reviewer/) | Checklist audytu bezpieczeństwa (OWASP, auth flow, wyciek danych) |

### 📈 Wzrost i Marketing

| Skill | Co robi |
|-------|---------|
| [growth-lead](skills/growth-lead/) | Wirtualny Head of Growth — lejek AARRR, planowanie OKR, wybór kanałów |
| [analytics-tracking](skills/analytics-tracking/) | Kompletny setup GA4 + GTM dla SaaS (eventy, UTM, konwersje) |
| [programmatic-seo](skills/programmatic-seo/) | SEO na skalę — strony szablonowe dla wzorców "[usługa] + [miasto]" |
| [cold-email](skills/cold-email/) | Sekwencje cold outreach z personalizacją |

### 🎨 Design System

| Skill | Co robi |
|-------|---------|
| [design-system-themes](skills/design-system-themes/) | Implementacja wielu motywów (6 motywów, CSS variables, React Context) |
| [design-system-components](skills/design-system-components/) | Ujednolicone tokeny designu (spacing, shadows, typografia) |
| [design-system-checklist](skills/design-system-checklist/) | Pipeline wdrożenia: audyt → normalizacja → polish |

### 🤖 AI i Orkiestracja

| Skill | Co robi |
|-------|---------|
| [agent-hierarchy](skills/agent-hierarchy/) | Orkiestracja wielu agentów (5 ról, granice domen, delegacja) |
| [ai-token-counter](skills/ai-token-counter/) | Śledzenie kosztów API AI z logowaniem fire-and-forget |

### 🔧 DevOps

| Skill | Co robi |
|-------|---------|
| [vercel-supabase-debugger](skills/vercel-supabase-debugger/) | Drzewo decyzyjne debugowania problemów Vercel + Supabase na produkcji |

## Jak działają skille

Każdy skill zawiera:
- **Triggery** — frazy, które go aktywują ("dodaj multi-tenant auth", "strategia wzrostu")
- **Zależności** — inne skille, z którymi współpracuje
- **Instrukcje** — krok po kroku jak zaimplementować
- **Przykłady** — snippety kodu i szablony
- **Pułapki** — częste błędy do uniknięcia

Claude czyta skill, gdy wykryje pasujący trigger i automatycznie stosuje instrukcje.

## Zakładany stack

Te skille zakładają nowoczesny stack SaaS:
- **Frontend:** React 18+ / Next.js 14+ z App Router
- **Backend:** Supabase (PostgreSQL + Auth + RLS + Edge Functions)
- **Hosting:** Vercel (Fluid Compute)
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **Język:** TypeScript

Większość skilli adaptuje się do innych stacków — wzorce są uniwersalne, nawet jeśli przykłady używają konkretnych narzędzi.

## Współtworzenie

Znalazłeś błąd? Masz ulepszenie? Pull requesty mile widziane.

Przy dodawaniu skilla:
1. Zachowaj format SKILL.md (frontmatter + triggery + instrukcje + przykłady + pułapki)
2. Skill musi być samodzielny (bez zależności od prywatnej infrastruktury)
3. Dołącz przykłady z prawdziwego świata, nie zabawkowy kod
4. Dodaj sekcję "Pitfalls" — tam jest prawdziwa wartość

## Licencja

MIT — używaj tych skilli jak chcesz.

---

Stworzone przez [@DariuszCiesielski](https://github.com/DariuszCiesielski) • Wyciągnięte z budowania 15+ produktów SaaS z Claude Code
