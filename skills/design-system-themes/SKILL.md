---
name: design-system-themes
description: Definitions of 6 themes (Classic, Dark, Glass, Minimal, Gradient, Corporate) with TypeScript interfaces and CSS custom properties. Color palettes, WCAG contrast, var(--) vs hardcoded consistency rules. Use when creating/editing themes or adding CSS variables to a project.
---

# Design System — Themes and CSS Variables

## Triggers

- "add theme", "new theme", "edit theme"
- "CSS variables", "custom properties", "color palette"
- "contrast", "WCAG", "glassmorphism"
- "scrollbar dark theme", "contrast issue"

## Dependencies

```bash
npm install lucide-react
# Tailwind CSS (CDN or npm)
```

---

## 1. File Structure

```
themes/
├── types.ts             # TypeScript interfaces
├── index.ts             # Export all themes
├── default.ts           # Light theme (Classic)
├── dark.ts              # Dark theme
├── glass.ts             # Glassmorphism theme (default)
├── minimal.ts           # Minimalist theme
├── gradient.ts          # Gradient theme
└── corporate.ts         # Corporate theme
```

---

## 2. TypeScript Interfaces

### themes/types.ts

```typescript
export interface ThemeColors {
  // Main backgrounds
  bgPrimary: string;
  bgSecondary: string;
  bgTertiary: string;
  bgAccent: string;

  // Sidebar
  sidebarBg: string;
  sidebarText: string;
  sidebarHover: string;
  sidebarActive: string;

  // Header
  headerBg: string;
  headerGradient: string;
  headerText: string;

  // Text
  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  textInverse: string;

  // Borders
  borderPrimary: string;
  borderSecondary: string;
  borderAccent: string;

  // Accent/Brand
  accentPrimary: string;
  accentHover: string;
  accentLight: string;

  // States
  success: string;
  successLight: string;
  warning: string;
  warningLight: string;
  error: string;
  errorLight: string;
  info: string;
  infoLight: string;

  // Effects
  shadow: string;
  shadowLg: string;
  overlay: string;
  glassBg?: string;
  blur?: string;

  // Scrollbar
  scrollbarTrack: string;
  scrollbarThumb: string;
  scrollbarThumbHover: string;
}

export interface ThemeEffects {
  backdropBlur?: boolean;
  glassmorphism?: boolean;
  gradients?: boolean;
  softShadows?: boolean;
}

export interface Theme {
  id: string;
  name: string;
  description: string;
  colors: ThemeColors;
  effects?: ThemeEffects;
}

export type ThemeId = 'default' | 'dark' | 'glass' | 'minimal' | 'gradient' | 'corporate';
```

---

## 3. Theme Definitions

### themes/default.ts (Classic)

```typescript
import { Theme } from './types';

export const defaultTheme: Theme = {
  id: 'default',
  name: 'Classic',
  description: 'Light theme with blue accents',
  colors: {
    bgPrimary: '#f8fafc',
    bgSecondary: '#ffffff',
    bgTertiary: '#f1f5f9',
    bgAccent: '#e2e8f0',

    sidebarBg: '#0f172a',
    sidebarText: '#cbd5e1',
    sidebarHover: '#1e293b',
    sidebarActive: '#2563eb',

    headerBg: '#0f172a',
    headerGradient: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #1e3a8a 100%)',
    headerText: '#ffffff',

    textPrimary: '#1e293b',
    textSecondary: '#475569',
    textMuted: '#94a3b8',
    textInverse: '#ffffff',

    borderPrimary: '#e2e8f0',
    borderSecondary: '#cbd5e1',
    borderAccent: '#3b82f6',

    accentPrimary: '#2563eb',
    accentHover: '#1d4ed8',
    accentLight: '#dbeafe',

    success: '#10b981', successLight: '#d1fae5',
    warning: '#f59e0b', warningLight: '#fef3c7',
    error: '#ef4444', errorLight: '#fee2e2',
    info: '#3b82f6', infoLight: '#dbeafe',

    shadow: '0 1px 3px rgba(0,0,0,0.1)',
    shadowLg: '0 10px 15px -3px rgba(0,0,0,0.1)',
    overlay: 'rgba(15, 23, 42, 0.6)',

    scrollbarTrack: '#f1f1f1',
    scrollbarThumb: '#cbd5e1',
    scrollbarThumbHover: '#94a3b8',
  }
};
```

### themes/dark.ts (Dark)

```typescript
import { Theme } from './types';

export const darkTheme: Theme = {
  id: 'dark',
  name: 'Dark',
  description: 'Elegant dark theme',
  colors: {
    bgPrimary: '#0f172a',
    bgSecondary: '#1e293b',
    bgTertiary: '#334155',
    bgAccent: '#475569',

    sidebarBg: '#020617',
    sidebarText: '#94a3b8',
    sidebarHover: '#1e293b',
    sidebarActive: '#3b82f6',

    headerBg: '#020617',
    headerGradient: 'linear-gradient(135deg, #020617 0%, #0f172a 50%, #172554 100%)',
    headerText: '#f1f5f9',

    textPrimary: '#f1f5f9',
    textSecondary: '#cbd5e1',
    textMuted: '#64748b',
    textInverse: '#0f172a',

    borderPrimary: '#334155',
    borderSecondary: '#475569',
    borderAccent: '#60a5fa',

    accentPrimary: '#3b82f6',
    accentHover: '#60a5fa',
    accentLight: '#1e3a8a',

    success: '#34d399', successLight: '#064e3b',
    warning: '#fbbf24', warningLight: '#78350f',
    error: '#f87171', errorLight: '#7f1d1d',
    info: '#60a5fa', infoLight: '#1e3a8a',

    shadow: '0 4px 12px rgba(0,0,0,0.4)',
    shadowLg: '0 20px 25px -5px rgba(0,0,0,0.5)',
    overlay: 'rgba(0, 0, 0, 0.7)',

    scrollbarTrack: '#1e293b',
    scrollbarThumb: '#475569',
    scrollbarThumbHover: '#64748b',
  }
};
```

### themes/glass.ts (Glass — default)

```typescript
import { Theme } from './types';

export const glassTheme: Theme = {
  id: 'glass',
  name: 'Glass',
  description: 'Modern glassmorphism effect',
  colors: {
    bgPrimary: '#0f172a',
    bgSecondary: 'rgba(30, 41, 59, 0.8)',
    bgTertiary: 'rgba(51, 65, 85, 0.6)',
    bgAccent: 'rgba(71, 85, 105, 0.5)',

    sidebarBg: 'rgba(2, 6, 23, 0.9)',
    sidebarText: '#94a3b8',
    sidebarHover: 'rgba(30, 41, 59, 0.8)',
    sidebarActive: '#3b82f6',

    headerBg: 'rgba(2, 6, 23, 0.8)',
    headerGradient: 'linear-gradient(135deg, rgba(2,6,23,0.9) 0%, rgba(15,23,42,0.8) 50%, rgba(23,37,84,0.9) 100%)',
    headerText: '#f1f5f9',

    textPrimary: '#f1f5f9',
    textSecondary: '#cbd5e1',
    textMuted: '#64748b',
    textInverse: '#0f172a',

    borderPrimary: 'rgba(148, 163, 184, 0.2)',
    borderSecondary: 'rgba(148, 163, 184, 0.3)',
    borderAccent: '#60a5fa',

    accentPrimary: '#3b82f6',
    accentHover: '#60a5fa',
    accentLight: 'rgba(59, 130, 246, 0.2)',

    success: '#34d399', successLight: 'rgba(52, 211, 153, 0.2)',
    warning: '#fbbf24', warningLight: 'rgba(251, 191, 36, 0.2)',
    error: '#f87171', errorLight: 'rgba(248, 113, 113, 0.2)',
    info: '#60a5fa', infoLight: 'rgba(96, 165, 250, 0.2)',

    shadow: '0 8px 32px rgba(0,0,0,0.3)',
    shadowLg: '0 25px 50px -12px rgba(0,0,0,0.5)',
    overlay: 'rgba(0, 0, 0, 0.6)',
    glassBg: 'rgba(255, 255, 255, 0.05)',
    blur: '12px',

    scrollbarTrack: 'rgba(30, 41, 59, 0.5)',
    scrollbarThumb: 'rgba(100, 116, 139, 0.5)',
    scrollbarThumbHover: 'rgba(148, 163, 184, 0.5)',
  },
  effects: {
    glassmorphism: true,
    backdropBlur: true,
  }
};
```

### themes/index.ts

```typescript
import { Theme } from './types';
import { defaultTheme } from './default';
import { darkTheme } from './dark';
import { glassTheme } from './glass';
// ... import minimalTheme, gradientTheme, corporateTheme

export const themes: Theme[] = [
  defaultTheme, darkTheme, glassTheme,
  // minimalTheme, gradientTheme, corporateTheme,
];

export { defaultTheme, darkTheme, glassTheme };
export type { Theme, ThemeId, ThemeColors, ThemeEffects } from './types';

export const getThemeById = (id: string): Theme => {
  return themes.find(t => t.id === id) || glassTheme; // default: glass
};
```

> **Note:** The minimal, gradient, and corporate themes follow the same structure. Create them following the default/dark/glass pattern.

---

## 4. CSS Patterns with Custom Properties

### Buttons

```tsx
// Primary
<button
  className="px-4 py-2 rounded-lg font-medium transition-all"
  style={{
    backgroundColor: 'var(--accent-primary)',
    color: 'var(--text-inverse)',
  }}
  onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--accent-hover)'}
  onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--accent-primary)'}
>
  Button
</button>

// Secondary
<button
  className="px-4 py-2 rounded-lg font-medium border transition-all"
  style={{
    backgroundColor: 'transparent',
    borderColor: 'var(--border-primary)',
    color: 'var(--text-primary)',
  }}
>
  Button
</button>
```

### Cards

```tsx
<div
  className="rounded-xl p-6 border transition-all"
  style={{
    backgroundColor: 'var(--bg-secondary)',
    borderColor: 'var(--border-primary)',
    boxShadow: 'var(--shadow)',
  }}
>
  <h3 style={{ color: 'var(--text-primary)' }}>Title</h3>
  <p style={{ color: 'var(--text-secondary)' }}>Description</p>
</div>
```

### Header with Gradient

```tsx
<header
  className="py-16 px-6 relative"
  style={{ backgroundColor: 'var(--header-bg)', color: 'var(--header-text)' }}
>
  <div className="absolute inset-0 opacity-50" style={{ background: 'var(--header-gradient)' }} />
  <div className="relative z-30">{/* Header content */}</div>
</header>
```

---

## 5. Contrast on Dark Themes

### Scrollbar

```typescript
// WRONG - nearly invisible on dark background
scrollbarTrack: 'rgba(255, 255, 255, 0.05)',   // contrast ~1.2:1
scrollbarThumb: 'rgba(255, 255, 255, 0.2)',    // contrast ~1.8:1

// RIGHT - clearly visible
scrollbarTrack: 'rgba(30, 41, 59, 0.5)',       // slate-800 base
scrollbarThumb: 'rgba(100, 116, 139, 0.5)',    // slate-500 base, contrast ~4:1
```

**Minimum contrast ratios:**
- Thumb vs Track: min. 3:1 (WCAG for interactive elements)
- Track vs background: min. 1.5:1 (decorative element)

### Borders

```typescript
// WRONG
borderPrimary: 'rgba(255, 255, 255, 0.2)',

// RIGHT
borderPrimary: 'rgba(148, 163, 184, 0.2)',   // slate-400 base
```

### Glassmorphism Backgrounds

```typescript
// WRONG - too transparent
bgSecondary: 'rgba(255, 255, 255, 0.1)',

// RIGHT - preserves glassmorphism but has structure
bgSecondary: 'rgba(30, 41, 59, 0.8)',    // slate-800 base
```

### Text

```typescript
// WRONG - harsh white, causes eye strain
textPrimary: '#ffffff',

// RIGHT - softer, contrast 14:1 on #0f172a
textPrimary: '#f1f5f9',  // slate-100
```

---

## 6. Style Consistency Rules

### Rule: NEVER mix `var(--)` with hardcoded Tailwind in the same container

**"Light island" pattern** — modal on white background:
```tsx
<div style={{ backgroundColor: 'var(--overlay)' }}>
  <div className="bg-white rounded-xl">
    <input className="bg-slate-50 text-slate-900 border-slate-200 ..." />
  </div>
</div>
```

**"Full integration" pattern** — container using CSS variables:
```tsx
<div style={{ backgroundColor: 'var(--bg-secondary)' }}>
  <input style={{
    backgroundColor: 'var(--bg-primary)',
    color: 'var(--text-primary)',
    borderColor: 'var(--border-primary)',
  }} />
</div>
```

### Decision Rule
- Decision is **per container** (modal, section, panel), NOT per element
- LoginForm = full integration | Data modals = light island | Admin panel = full integration

## Pitfalls

### 1. Mixing var(--) with hardcoded Tailwind
**Problem:** `text-slate-700` (#334155) unreadable on dark `var(--bg-secondary)` background.
**Solution:** One pattern per container — either all var(--), or all Tailwind classes.

### 2. Missing fallback for glassBg/blur
**Problem:** Theme without `effects.glassmorphism` ignores `glassBg` and `blur`, but CSS variables remain empty.
**Solution:** Set fallback in `applyThemeToDOM`: `root.style.setProperty('--glass-bg', theme.colors.glassBg || 'transparent')`.

### 3. Scrollbar rgba(white) on dark background
**Problem:** `rgba(255,255,255,0.05)` is invisible — contrast 1.2:1.
**Solution:** Use slate base (`rgba(100, 116, 139, 0.5)`) instead of white base.
