---
name: supabase-auth-admin-roles
description: Admin/user role separation in Supabase with SECURITY DEFINER, admins table, is_admin() function, RLS policies, AuthContext with admin check, AdminRoute. Debugging RLS recursion. Use when configuring admin/user roles in Supabase.
---

# Supabase Auth — Admin/User Role Separation

Skill for configuring admin/user role separation in Supabase with proper RLS policies, avoiding the common infinite recursion pitfall.

## Triggers

- "add admin roles"
- "is_admin"
- "role separation"
- "SECURITY DEFINER"
- "admins table"
- "RLS recursion"

## When to Use

- Creating an admin/user role system in Supabase
- Fixing "infinite recursion detected in policy" errors
- Configuring RLS policies that check user roles
- Debugging 500 errors on REST API related to RLS

---

## 1. The RLS Recursion Problem

When an RLS policy on the `admins` table checks whether the user is an admin by querying the same `admins` table, Supabase detects infinite recursion and returns a 500 error.

**Example of the problem:**

```sql
-- BAD: policy on admins table queries the admins table
CREATE POLICY "bad_policy" ON public.admins
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.admins WHERE user_id = auth.uid())
  );
-- Result: "infinite recursion detected in policy" -> 500 error
```

**Solution:** Use a `SECURITY DEFINER` function that bypasses RLS and safely checks admin status.

---

## 2. Creating the Admins Table

```sql
CREATE TABLE public.admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
```

---

## 3. The is_admin() Function with SECURITY DEFINER

The function bypasses RLS thanks to the `SECURITY DEFINER` flag — it executes with the owner's permissions (typically `postgres`), not the caller's.

```sql
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.admins WHERE user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Permissions — authenticated and anon (anon needed for pre-login checks)
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
```

---

## 4. RLS Policies for the Admins Table

```sql
-- Users can check their own admin status (no recursion — only checks their own row)
CREATE POLICY "Users can check own admin status" ON public.admins
    FOR SELECT USING (user_id = auth.uid());

-- Admins can manage all admins (uses SECURITY DEFINER function)
CREATE POLICY "Admins can manage all admins" ON public.admins
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
```

---

## 5. RLS Policies for Other Tables (is_admin() Pattern)

Every table requiring admin-only access uses the same pattern:

```sql
-- Example: applications table
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage applications" ON public.applications
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Example: table with data visible to users but editable by admins only
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read settings" ON public.settings
    FOR SELECT USING (true);

CREATE POLICY "Admins can modify settings" ON public.settings
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
```

---

## 6. Frontend: AuthContext with checkAdminStatus

```typescript
// contexts/AuthContext.tsx
import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import type { User, Session } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isAdmin: boolean;
  isLoading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        checkAdminStatus(session.user.id);
      } else {
        setIsLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        if (session?.user) {
          await checkAdminStatus(session.user.id);
        } else {
          setIsAdmin(false);
          setIsLoading(false);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  async function checkAdminStatus(userId: string) {
    try {
      // Priority: RPC function (SECURITY DEFINER — most secure)
      const { data, error } = await supabase.rpc('is_admin');

      if (error) {
        // Fallback: direct query (works thanks to the SELECT own row policy)
        const { data: adminData } = await supabase
          .from('admins')
          .select('id')
          .eq('user_id', userId)
          .single();
        setIsAdmin(!!adminData);
      } else {
        setIsAdmin(data === true);
      }
    } catch {
      setIsAdmin(false);
    } finally {
      setIsLoading(false);
    }
  }

  const signOut = async () => {
    await supabase.auth.signOut();
    setIsAdmin(false);
  };

  return (
    <AuthContext.Provider value={{ user, session, isAdmin, isLoading, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
```

---

## 7. Frontend: AdminRoute Component

```typescript
// components/auth/AdminRoute.tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';

export function AdminRoute({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, isLoading } = useAuth();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  if (!isAdmin) {
    return <Navigate to="/no-access" replace />;
  }

  return <>{children}</>;
}
```

**Usage in router:**

```typescript
<Route path="/admin/*" element={
  <AdminRoute>
    <AdminDashboard />
  </AdminRoute>
} />
```

---

## 8. Common Issues

### Issue: "infinite recursion detected in policy"

**Cause:** An RLS policy queries the same table it protects.

**Solution:** Use a `SECURITY DEFINER` function as described in section 3.

### Issue: Users can't check their admin status

**Cause:** RLS blocks all reads from the admins table.

**Solution:** Add a policy allowing users to read their own row:

```sql
CREATE POLICY "Users can check own admin status" ON public.admins
    FOR SELECT USING (user_id = auth.uid());
```

### Issue: Anon users getting errors

**Cause:** Missing `GRANT EXECUTE` for the `anon` role.

**Solution:**

```sql
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
```

---

## 9. Verification Queries

```sql
-- Check RLS status on tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- Check policies
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public';

-- Test the is_admin() function (as a logged-in user)
SELECT public.is_admin();

-- Check who is an admin
SELECT a.user_id, u.email
FROM public.admins a
JOIN auth.users u ON u.id = a.user_id;
```

---

## 10. Debugging RLS Recursion

When you get a **500 Internal Server Error** on the Supabase REST API, but the same SQL works in the SQL Editor — it's almost always an RLS recursion problem.

### Diagnostic Queries

```sql
-- 1. Check if helper functions have SECURITY DEFINER
SELECT proname, prosecdef, proowner::regrole
FROM pg_proc
WHERE proname IN ('is_admin');
-- prosecdef MUST be true

-- 2. Show full policy definitions (look for self-referencing subqueries)
SELECT policyname, tablename, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;

-- 3. Show function source code
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'is_admin';

-- 4. Test as authenticated user (simulates REST API)
SET request.jwt.claims = '{"sub": "YOUR_USER_UUID"}';
SET role = 'authenticated';
SELECT * FROM public.admins LIMIT 5;
RESET role;
```

---

## 11. Symptoms and Fixes

| Symptom | Cause | Solution |
|---------|-------|----------|
| 500 on REST, works in SQL Editor | RLS recursion | Add `SECURITY DEFINER` to helper functions |
| Empty result on REST, data visible in SQL Editor | RLS blocks access | Check `USING` conditions in policies |
| 403 Forbidden | Missing `GRANT` | `GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated` |
| `prosecdef = false` after `CREATE OR REPLACE` | Function not updated | Re-run with explicit `SECURITY DEFINER` |

---

## Pitfalls

### 1. Recursion in RLS policy
**Problem:** A subquery on the same table inside an RLS policy (e.g., `EXISTS (SELECT ... FROM admins WHERE ...)` in a policy on `admins`) causes infinite recursion.
**Solution:** Extract the logic into a separate `SECURITY DEFINER` function and call it from the policy.

### 2. Testing policies in SQL Editor
**Problem:** SQL Editor bypasses RLS — tests pass, but the REST API returns access errors.
**Solution:** Always test with JWT simulation: `SET request.jwt.claims = '{"sub": "USER_UUID"}'; SET role = 'authenticated';`

### 3. auth.uid() = NULL for unauthenticated users
**Problem:** A policy checking `auth.uid() = user_id` without NULL handling blocks access unpredictably.
**Solution:** Add an explicit `auth.uid() IS NOT NULL` check or set `enabled: !!user` in the AuthContext hook.

### 4. SECURITY DEFINER without explicit flag
**Problem:** `CREATE OR REPLACE FUNCTION` does not change the `prosecdef` flag if you don't explicitly specify `SECURITY DEFINER` — the function runs as `SECURITY INVOKER`.
**Solution:** Always add `SECURITY DEFINER SET search_path = public` when creating and modifying functions.

### 5. Missing GRANT EXECUTE for anon role
**Problem:** A function with `GRANT EXECUTE ... TO authenticated` won't work for unauthenticated sessions.
**Solution:** Add `GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;` if the function needs to be accessible before login.
