---
name: design-system-checklist
description: Implementation and testing checklists for themes, best practices, auto-feedback template, UI polish pipeline (audit->normalize->polish), onboarding via /teach-design. Use when deploying the design system in a new project, testing themes, or polishing UI after a feature branch.
---

# Design System — Checklist and Testing

## Triggers

- "theme checklist", "test themes", "verify design system"
- "deploy design system in project", "theme implementation"
- "which projects use the design system"
- "auto-feedback design system"

---

## 1. Implementation Checklist

When deploying the design system in a new project:

1. [ ] Create `themes/` folder with theme files (see skill `design-system-themes`)
2. [ ] Create `contexts/ThemeContext.tsx` (see skill `design-system-components`)
3. [ ] Wrap the app in `<ThemeProvider>`
4. [ ] Add `UserMenu` to the header (top-right corner)
5. [ ] Replace hardcoded colors with `var(--color-name)`
6. [ ] Set a unique `THEME_STORAGE_KEY` (e.g., `MY_SAAS_THEME`)
7. [ ] Test all themes (see testing checklist below)
8. [ ] Set the default theme in `getThemeById()`

### Projects with shadcn/ui — additional steps:

9. [ ] Add `mapToShadcnVariables()` mapping to `applyThemeToDOM()`
10. [ ] Remove `className="dark"` from `<html>`
11. [ ] Add `suppressHydrationWarning` to `<html>` (Next.js)
12. [ ] Test shadcn components (Button, Card, Sidebar) after theme change

---

## 2. Theme Testing Checklist

After adding a new component or theme, go through each item on **Glass**, **Dark**, and **Classic**:

1. [ ] **Scrollbar** — visible and interactive (thumb clearly distinguishable from track)
2. [ ] **Form fields** — text visible in all input/textarea/select elements
3. [ ] **Labels and descriptions** — readable on container background (contrast min. 4.5:1)
4. [ ] **Borders** — visible edges on cards, inputs, separators
5. [ ] **Hover/focus** — visible state change on interaction
6. [ ] **Dropdown/select** — option text visible, dropdown background distinguishable
7. [ ] **Info/error/warning** — info boxes readable and distinguishable
8. [ ] **Inline editing** — edited text visible in table cells

### Form Checklist

1. [ ] Every input/textarea has an explicit text color
2. [ ] Tested with Glass, Dark, and Classic themes
3. [ ] Placeholder visible (`placeholder-slate-400`)
4. [ ] Labels use `var(--text-secondary)` / `var(--text-muted)` on var(--) containers
5. [ ] Info/error boxes use `var(--info-light)` / `var(--error-light)`
6. [ ] Toggle/selection uses `var(--accent-primary)` / `var(--accent-light)`

---

## 3. Best Practices

- **z-index**: Header with dropdown — `z-30` or higher
- **overflow**: Avoid `overflow-hidden` on headers (clips dropdowns)
- **backdrop-filter**: `blur(12px)` for glassmorphism
- **localStorage**: Prefix key with app name (`APP_THEME`)
- **Accessibility**: Text contrast per WCAG (min. 4.5:1 normal, 3:1 large)
- **Consistency**: One pattern per container — either var(--) or hardcoded Tailwind

---

## 4. UI Polish Pipeline (after feature branch)

Workflow for leveling up UI quality after implementation. Run before merging to main.

### Triggers

- "polish UI", "improve UI quality"
- "audit->normalize->polish", "UI pipeline"
- After completing a feature branch with TSX components

### Steps

```
Step 1: AUDIT — identify issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -> Scan changed TSX/CSS files (git diff --name-only main)
  -> Check for anti-patterns (see below)
  -> Check the theme testing checklist (section 2)
  -> Output: list of issues with priority (critical/important/cosmetic)

Step 2: NORMALIZE — align with design system
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -> Replace hardcoded colors with var(--)
  -> Replace generic divs with shadcn components (Card, Badge, Alert)
  -> Align spacing to 4px scale (p-1, p-2, p-3, p-4, p-6, p-8)
  -> Add missing states: empty, loading, error
  -> Check typographic hierarchy (not everything 14-16px)

Step 3: POLISH — final touches
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -> Add hover/focus states to interactive elements
  -> Add transitions (150-200ms ease-out) to buttons and cards
  -> Check WCAG 4.5:1 contrast on key text
  -> Verify responsiveness (375px, 768px, 1024px)
  -> If .design-config.md exists — check consistency with project config
```

### When NOT to run

- Changes only in logic (no TSX/CSS) — pipeline is unnecessary
- Production hotfix — priority = speed, not polish
- Prototype/MVP with "skip polish" flag — user consciously opts out

---

## 5. Common Anti-Patterns

When editing TSX/CSS files, watch for these anti-patterns:

- No typographic hierarchy (everything 14-16px)
- Hardcoded colors instead of `var(--)`
- Generic bordered divs instead of shadcn components
- Missing empty/loading/error states
- Animations >300ms, bounce/elastic easing
- Cards inside cards (nested cards)
- Rainbow accents (5+ colors)

---

## 6. Onboarding: /teach-design

One-time design context configuration per project. Generates `.design-config.md` in the project root. Subsequent design system skill runs read this file.

### Triggers

- "/teach-design", "configure design", "design system onboarding"
- On first use of the design system in a new project

### Procedure

1. **Ask the user about:**
   - Interface type: dashboard / landing page / SaaS app / CMS / e-commerce
   - Visual tone: professional-dark / minimal / creative-colorful / corporate
   - Accent color: (hex or description, e.g., "orange like Stripe")
   - Target audience: (e.g., "small business owners aged 30-50")
   - Visual references: (URL or name of existing project)

2. **Save to `.design-config.md`:**

```markdown
# Design Config — {{PROJECT_NAME}}
# Generated by /teach-design — {{DATE}}
# Run /teach-design again to update

ui_type: {{dashboard | landing | saas | cms | ecommerce}}
tone: {{professional-dark | minimal | creative | corporate}}
accent_color: {{hex}}
audience: {{description}}
references: {{list of URLs or project names}}
default_theme: {{glass | dark | classic | minimal | gradient | corporate}}
main_font: {{Geist Sans | other}}
mono_font: {{Geist Mono | other}}
```

3. **Confirm:** "Configuration saved to `.design-config.md`. The UI Polish pipeline and checklists will use this context."

### Integration

- **UI Polish Pipeline** (section 4) -> step 3 checks `.design-config.md`
- **design-system-themes** -> suggests theme based on `tone`
- **design-system-components** -> selects shadcn mapping based on `ui_type`

---

## 7. Auto-Feedback (self-analysis after use)

After finishing work with the design system, the agent generates a report if needed.

### Rules
- Report ONLY when there's something valuable (anomalies, missing instructions, suggestions)
- If everything worked without issues — DO NOT generate a report (no report = OK)
- MAX 20 lines — concise and to the point

### Format

```markdown
# Feedback: design-system
Date: {{DATE}}
Project: {{PROJECT_NAME}}

## Anomalies and Issues
- [description]

## Missing Instructions
- [what was missing]

## Improvement Suggestions
- [proposals]
```
