---
name: design-system-components
description: ThemeContext (provider + hook), UserMenu with theme switcher, shadcn/ui variable mapping, app integration. Use when adding a theme switcher, integrating with shadcn, or wrapping an app in ThemeProvider.
---

# Design System — Components and Integration

## Triggers

- "add theme switcher", "ThemeProvider", "ThemeContext"
- "UserMenu", "user menu"
- "shadcn theme integration", "shadcn mapping"
- "add dark mode", "wrap in ThemeProvider"

## Dependencies

```bash
npm install lucide-react
# Requires: skill design-system-themes (theme definitions)
```

---

## 1. ThemeContext

### contexts/ThemeContext.tsx

```typescript
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Theme, themes, getThemeById } from '../themes';

interface ThemeContextType {
  currentTheme: Theme;
  setTheme: (themeId: string) => void;
  themes: Theme[];
}

const ThemeContext = createContext<ThemeContextType | null>(null);
const THEME_STORAGE_KEY = 'APP_THEME'; // change prefix to your app name

const camelToKebab = (str: string): string =>
  str.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();

const applyThemeToDOM = (theme: Theme) => {
  const root = document.documentElement;

  Object.entries(theme.colors).forEach(([key, value]) => {
    if (value !== undefined) {
      root.style.setProperty(`--${camelToKebab(key)}`, value);
    }
  });

  // Effect classes
  root.classList.remove('theme-glass', 'theme-gradient', 'theme-minimal', 'theme-dark');
  if (theme.effects?.glassmorphism) root.classList.add('theme-glass');
  if (theme.effects?.gradients) root.classList.add('theme-gradient');
  if (theme.id === 'dark') root.classList.add('theme-dark');

  // Scrollbar
  updateScrollbarStyles(theme);
};

const updateScrollbarStyles = (theme: Theme) => {
  const styleId = 'theme-scrollbar-styles';
  let styleEl = document.getElementById(styleId) as HTMLStyleElement;
  if (!styleEl) {
    styleEl = document.createElement('style');
    styleEl.id = styleId;
    document.head.appendChild(styleEl);
  }
  styleEl.textContent = `
    ::-webkit-scrollbar { width: 8px; }
    ::-webkit-scrollbar-track { background: ${theme.colors.scrollbarTrack}; }
    ::-webkit-scrollbar-thumb { background: ${theme.colors.scrollbarThumb}; border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: ${theme.colors.scrollbarThumbHover}; }
  `;
};

export const ThemeProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [currentTheme, setCurrentTheme] = useState<Theme>(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(THEME_STORAGE_KEY);
      if (saved) return getThemeById(saved);
    }
    return getThemeById('glass'); // default theme
  });

  useEffect(() => {
    applyThemeToDOM(currentTheme);
    localStorage.setItem(THEME_STORAGE_KEY, currentTheme.id);
  }, [currentTheme]);

  useEffect(() => {
    applyThemeToDOM(currentTheme);
  }, []);

  const setTheme = (themeId: string) => setCurrentTheme(getThemeById(themeId));

  return (
    <ThemeContext.Provider value={{ currentTheme, setTheme, themes }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used within ThemeProvider');
  return context;
};
```

---

## 2. Mapping to shadcn/ui Variables

If the project uses **shadcn/ui**, ThemeContext must map colors to shadcn CSS variables. Without this, shadcn components won't react to theme changes.

### Add to `applyThemeToDOM()`:

```typescript
import type { ThemeColors } from '@/themes';

const mapToShadcnVariables = (colors: ThemeColors): Record<string, string> => ({
  '--background': colors.bgPrimary,
  '--foreground': colors.textPrimary,
  '--card': colors.bgSecondary,
  '--card-foreground': colors.textPrimary,
  '--popover': colors.bgSecondary,
  '--popover-foreground': colors.textPrimary,
  '--primary': colors.accentPrimary,
  '--primary-foreground': colors.textInverse,
  '--secondary': colors.bgTertiary,
  '--secondary-foreground': colors.textSecondary,
  '--muted': colors.bgTertiary,
  '--muted-foreground': colors.textMuted,
  '--accent': colors.bgAccent,
  '--accent-foreground': colors.textPrimary,
  '--destructive': colors.error,
  '--border': colors.borderPrimary,
  '--input': colors.borderPrimary,
  '--ring': colors.accentPrimary,
  '--sidebar': colors.sidebarBg,
  '--sidebar-foreground': colors.sidebarText,
  '--sidebar-primary': colors.accentPrimary,
  '--sidebar-primary-foreground': colors.textInverse,
  '--sidebar-accent': colors.sidebarHover,
  '--sidebar-accent-foreground': colors.sidebarText,
  '--sidebar-border': colors.borderPrimary,
  '--sidebar-ring': colors.accentPrimary,
});

// In applyThemeToDOM, after setting custom variables:
const shadcnVars = mapToShadcnVariables(theme.colors);
Object.entries(shadcnVars).forEach(([key, value]) => {
  root.style.setProperty(key, value);
});
```

### Important:
- Remove `className="dark"` from `<html>` — the theme controls colors dynamically
- Add `suppressHydrationWarning` to `<html>` (Next.js)
- `globals.css` with `:root` and `.dark` still exists as fallback, but ThemeProvider overrides the values

---

## 3. UserMenu

### components/UserMenu.tsx

```typescript
import React, { useState, useRef, useEffect } from 'react';
import { User, ChevronDown, LogOut, Palette, Check } from 'lucide-react';
import { useTheme } from '../contexts/ThemeContext';

interface UserMenuProps {
  userEmail?: string;
  displayName?: string;
  onSignOut: () => void;
  variant?: 'light' | 'dark';
}

const UserMenu: React.FC<UserMenuProps> = ({ userEmail, displayName, onSignOut, variant = 'light' }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [showThemes, setShowThemes] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const { currentTheme, setTheme, themes } = useTheme();

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setShowThemes(false);
      }
    };
    if (isOpen) document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  const renderColorPreview = (theme: typeof currentTheme) => (
    <div className="flex gap-0.5 shrink-0">
      <div className="w-3 h-3 rounded-l-sm" style={{ backgroundColor: theme.colors.accentPrimary }} />
      <div className="w-3 h-3" style={{ backgroundColor: theme.colors.sidebarBg }} />
      <div className="w-3 h-3 rounded-r-sm border" style={{ backgroundColor: theme.colors.bgSecondary, borderColor: theme.colors.borderPrimary }} />
    </div>
  );

  const isDark = variant === 'dark';

  return (
    <div ref={menuRef} className="relative">
      <button
        onClick={() => { setIsOpen(!isOpen); setShowThemes(false); }}
        className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-all ${
          isDark ? 'bg-white/10 hover:bg-white/20 text-white' : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
        }`}
      >
        <User className="w-4 h-4" />
        <span className="hidden sm:inline max-w-[120px] truncate">{displayName || userEmail?.split('@')[0]}</span>
        <ChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div
          className="absolute right-0 top-full mt-2 w-64 rounded-xl border py-2 z-50 overflow-hidden"
          style={{
            backgroundColor: 'var(--bg-secondary)',
            borderColor: 'var(--border-secondary)',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.1)',
            backdropFilter: 'blur(12px)',
          }}
        >
          {/* Email */}
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border-primary)' }}>
            <div className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{displayName || 'User'}</div>
            <div className="text-xs truncate" style={{ color: 'var(--text-muted)' }}>{userEmail}</div>
          </div>

          {/* Theme button */}
          <button
            onClick={() => setShowThemes(!showThemes)}
            className="w-full px-4 py-2.5 flex items-center gap-3 transition-colors"
            style={{ backgroundColor: showThemes ? 'var(--bg-accent)' : 'transparent' }}
          >
            <Palette className="w-4 h-4" style={{ color: 'var(--text-secondary)' }} />
            <span className="flex-1 text-left text-sm" style={{ color: 'var(--text-primary)' }}>Theme</span>
            {renderColorPreview(currentTheme)}
            <ChevronDown className={`w-4 h-4 transition-transform ${showThemes ? 'rotate-180' : ''}`} style={{ color: 'var(--text-muted)' }} />
          </button>

          {/* Theme list */}
          {showThemes && (
            <div className="border-t border-b my-1 py-1" style={{ borderColor: 'var(--border-primary)' }}>
              {themes.map((theme) => (
                <button
                  key={theme.id}
                  onClick={() => setTheme(theme.id)}
                  className="w-full px-4 py-2 flex items-center gap-3 transition-colors"
                  style={{ backgroundColor: currentTheme.id === theme.id ? 'var(--accent-light)' : 'transparent' }}
                >
                  {renderColorPreview(theme)}
                  <span className="flex-1 text-left text-sm" style={{ color: 'var(--text-primary)' }}>{theme.name}</span>
                  {currentTheme.id === theme.id && <Check className="w-4 h-4" style={{ color: 'var(--accent-primary)' }} />}
                </button>
              ))}
            </div>
          )}

          {/* Sign out */}
          <button
            onClick={onSignOut}
            className="w-full px-4 py-2.5 flex items-center gap-3 transition-colors"
            style={{ color: 'var(--error)' }}
          >
            <LogOut className="w-4 h-4" />
            <span className="text-sm">Sign Out</span>
          </button>
        </div>
      )}
    </div>
  );
};

export default UserMenu;
```

---

## 4. UserMenu Placement Rule

**ALWAYS** place in the **top-right corner of the header** — never in the sidebar or footer.

```
+------------------------------------------------+
|  [=]                              [User    v]  |  <- header, justify-between
+----------+-------------------------------------+
| Sidebar  |           Content                   |
| (nav     |                                     |
|  only)   |                                     |
|          |                                     |
+----------+-------------------------------------+
```

**Sidebar** = navigation. **Header** = user actions (UserMenu with themes and sign out).

---

## 5. App Integration

### index.tsx

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { ThemeProvider } from './contexts/ThemeContext';

const root = ReactDOM.createRoot(document.getElementById('root')!);
root.render(
  <React.StrictMode>
    <ThemeProvider>
      <App />
    </ThemeProvider>
  </React.StrictMode>
);
```

---

## 6. Font Colors in Forms

**CRITICAL:** Input/textarea fields must have **explicitly set text color** — dark themes may set a light color globally.

### On white background (light island)

```tsx
<input className="bg-white text-slate-900 p-2 border rounded" />
<textarea className="bg-white text-slate-900 p-3 border rounded" />
```

### On dark background (var(--) container)

```tsx
<input
  className="w-full px-4 py-2.5 rounded-lg border focus:ring-2 focus:ring-blue-500"
  style={{
    backgroundColor: 'var(--bg-primary)',
    color: 'var(--text-primary)',
    borderColor: 'var(--border-primary)',
  }}
/>
```

### Recommended Tailwind Classes

| Element | Text color class |
|---------|-----------------|
| Input on white background | `text-slate-900` |
| Input on dark background | `text-white` or `var(--text-primary)` |
| Placeholder | `placeholder-slate-400` |

## Pitfalls

### 1. Missing THEME_STORAGE_KEY prefix
**Problem:** Two apps on the same domain overwrite each other's theme in localStorage.
**Solution:** Change `APP_THEME` to a unique prefix (e.g., `MY_SAAS_THEME`, `DASHBOARD_THEME`).

### 2. className="dark" + ThemeProvider
**Problem:** `className="dark"` on `<html>` conflicts with dynamic theme — shadcn always renders dark.
**Solution:** Remove static `className="dark"`, ThemeProvider controls colors via var(--).

### 3. overflow-hidden on header
**Problem:** `overflow-hidden` on header clips the UserMenu dropdown.
**Solution:** Use `overflow-visible` or move the dropdown to a portal.
