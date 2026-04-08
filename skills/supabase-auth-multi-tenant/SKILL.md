---
name: supabase-auth-multi-tenant
description: Multi-tenant pattern with organizations in Supabase — organizations + organization_members tables, admin/member roles (enum), SECURITY DEFINER helpers (get_user_org_id, is_org_admin), org-scoped RLS policies, AuthContext with organization. Use when building multi-tenant applications.
---

# Supabase Auth — Multi-Tenant Organization Pattern

Skill for building multi-tenant applications with organizations, roles (admin/member), and org-scoped RLS policies in Supabase.

## Triggers

- "multi-tenant"
- "organizations"
- "organization_members"
- "org-scoped RLS"
- "get_user_org_id"

## When to Use

- Building applications where users belong to organizations
- Configuring admin/member roles within an organization context
- Creating RLS policies that restrict data to the user's organization
- Fixing RLS recursion errors in tables with self-referencing subqueries

---

## 1. Creating Tables

```sql
-- Custom enum for organization member roles
CREATE TYPE member_role AS ENUM ('admin', 'member');

-- Organizations table
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Organization members table
CREATE TABLE public.organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role member_role NOT NULL DEFAULT 'member',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

-- Enable RLS on both tables
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
```

---

## 2. SECURITY DEFINER Helper Functions

Both functions MUST have `SECURITY DEFINER` to avoid RLS recursion when called from policies on the same tables.

```sql
-- Returns the current user's organization_id
CREATE OR REPLACE FUNCTION get_user_org_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT organization_id
  FROM organization_members
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

-- Checks if the current user is an admin in the given organization
CREATE OR REPLACE FUNCTION is_org_admin(org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM organization_members
    WHERE user_id = auth.uid()
      AND organization_id = org_id
      AND role = 'admin'
  );
$$;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_user_org_id() TO authenticated;
GRANT EXECUTE ON FUNCTION is_org_admin(uuid) TO authenticated;
```

---

## 3. RLS Policies for organization_members

```sql
-- Members can see other members of their organization
CREATE POLICY "Members see org members" ON organization_members
  FOR SELECT
  USING (organization_id = get_user_org_id());

-- Admins can manage members of their organization
CREATE POLICY "Admins manage org members" ON organization_members
  FOR ALL
  USING (
    organization_id = get_user_org_id()
    AND is_org_admin(organization_id)
  );
```

---

## 4. RLS Pattern for Org-Scoped Tables

Every table with organization data uses the same pattern — `get_user_org_id()` for filtering and `is_org_admin()` for management.

```sql
-- Example: mailboxes table scoped to organization
ALTER TABLE public.mailboxes ENABLE ROW LEVEL SECURITY;

-- Members can see their organization's mailboxes
CREATE POLICY "Members see org mailboxes" ON mailboxes
  FOR SELECT
  USING (organization_id = get_user_org_id());

-- Admins can manage their organization's mailboxes
CREATE POLICY "Admins manage org mailboxes" ON mailboxes
  FOR ALL
  USING (
    organization_id = get_user_org_id()
    AND is_org_admin(organization_id)
  );
```

**Pattern for any table with an `organization_id` column:**

```sql
ALTER TABLE public.<TABLE> ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members see org <TABLE>" ON <TABLE>
  FOR SELECT
  USING (organization_id = get_user_org_id());

CREATE POLICY "Admins manage org <TABLE>" ON <TABLE>
  FOR ALL
  USING (
    organization_id = get_user_org_id()
    AND is_org_admin(organization_id)
  );
```

---

## 5. Frontend AuthContext with Organization

```typescript
// contexts/AuthContext.tsx
import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import type { User, Session } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isAdmin: boolean;
  organizationId: string | null;
  isLoading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [organizationId, setOrganizationId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const fetchUserRole = useCallback(async (userId: string) => {
    try {
      const { data } = await supabase
        .from('organization_members')
        .select('organization_id, role')
        .eq('user_id', userId)
        .limit(1)
        .single();

      if (data) {
        setOrganizationId(data.organization_id);
        setIsAdmin(data.role === 'admin');
      }
    } catch {
      // User does not belong to any organization
      setOrganizationId(null);
      setIsAdmin(false);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchUserRole(session.user.id);
      } else {
        setIsLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        if (session?.user) {
          await fetchUserRole(session.user.id);
        } else {
          setIsAdmin(false);
          setOrganizationId(null);
          setIsLoading(false);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, [fetchUserRole]);

  const signOut = async () => {
    await supabase.auth.signOut();
    setIsAdmin(false);
    setOrganizationId(null);
  };

  return (
    <AuthContext.Provider value={{
      user,
      session,
      isAdmin,
      organizationId,
      isLoading,
      signOut
    }}>
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

## 6. Common Pitfall: Self-Referencing Subqueries

NEVER use subqueries on the same table inside RLS policies — this causes infinite recursion and a 500 error.

```sql
-- BAD: EXISTS subquery on organization_members inside its own policy
CREATE POLICY "bad_policy" ON organization_members
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM organization_members om
            WHERE om.user_id = auth.uid()
            AND om.role = 'admin')
  );
-- Result: infinite recursion -> 500 error!

-- GOOD: Use a SECURITY DEFINER function instead
CREATE POLICY "good_policy" ON organization_members
  FOR ALL
  USING (is_org_admin(organization_id));
```

**How to identify the problem:**
- REST API returns 500, but the same SQL works in the SQL Editor
- SQL Editor bypasses RLS, so recursion does not occur there
- Supabase logs show "infinite recursion detected in policy"

---

## Pitfalls

### 1. Self-referencing subquery = 500
**Problem:** A subquery on the same table inside an RLS policy (e.g., `EXISTS (SELECT ... FROM organization_members WHERE ...)` in a policy on `organization_members`) causes infinite recursion.
**Solution:** Extract the logic into a separate `SECURITY DEFINER` function and call it from the policy.

### 2. prosecdef=false after CREATE OR REPLACE
**Problem:** If a function was previously created WITHOUT `SECURITY DEFINER`, and you then run `CREATE OR REPLACE` with `SECURITY DEFINER`, the `prosecdef` flag may not update.
**Solution:** Use `DROP FUNCTION` + `CREATE FUNCTION` instead of `CREATE OR REPLACE`. Verify:
```sql
SELECT proname, prosecdef FROM pg_proc WHERE proname = 'get_user_org_id';
-- prosecdef MUST be true
```

### 3. Missing SET search_path = public
**Problem:** A `SECURITY DEFINER` function without an explicit `SET search_path = public` may not find tables or may reference the wrong schema.
**Solution:** Always add `SET search_path = public` in the function definition:
```sql
CREATE OR REPLACE FUNCTION get_user_org_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public  -- <- required!
AS $$ ... $$;
```

### 4. User in multiple organizations
**Problem:** `get_user_org_id()` with `LIMIT 1` returns only one organization. If a user belongs to multiple organizations, results may be unpredictable.
**Solution:** Add an `is_default` column to `organization_members` or pass `organization_id` as a session parameter. Alternatively, refactor to `get_user_org_ids()` returning `uuid[]`.

### 5. Testing policies in SQL Editor
**Problem:** SQL Editor bypasses RLS — tests pass, but the REST API returns errors.
**Solution:** Test with JWT simulation:
```sql
SET request.jwt.claims = '{"sub": "YOUR_USER_UUID"}';
SET role = 'authenticated';
SELECT * FROM organization_members LIMIT 5;
RESET role;
```
