-- =============================================================================
-- 20260524_010_admin_role_infrastructure
--
-- Foundation for all later admin policy fixes (audit-final.md F-3, F-4, F-5).
--
-- Replaces the client-side ADMIN_EMAILS allowlist with a DB-side role table.
-- Adds public.is_admin() so RLS policies and SECURITY DEFINER functions can
-- gate writes on real admin status (not a JS bundle the attacker can ignore).
--
-- After this migration:
--   • public.app_roles holds (user_id, role) tuples
--   • public.is_admin() returns true iff caller has role='admin'
--   • The two existing admin emails are bootstrapped automatically
-- =============================================================================

-- ── Roles table ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.app_roles (
  user_id    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL CHECK (role IN ('admin', 'support')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_app_roles_role ON public.app_roles(role);

-- ── RLS: only admins read; only admins manage. Avoid self-promotion. ────────
ALTER TABLE public.app_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_roles_admin_select" ON public.app_roles;
DROP POLICY IF EXISTS "app_roles_admin_insert" ON public.app_roles;
DROP POLICY IF EXISTS "app_roles_admin_update" ON public.app_roles;
DROP POLICY IF EXISTS "app_roles_admin_delete" ON public.app_roles;

-- Read: admins see the full table. Non-admins see nothing.
CREATE POLICY "app_roles_admin_select" ON public.app_roles
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- Write: only admins can grant or revoke roles. WITH CHECK prevents an
-- admin from being tricked into inserting/updating a row that wouldn't
-- pass the USING clause (e.g. via a hostile RETURNING clause).
CREATE POLICY "app_roles_admin_insert" ON public.app_roles
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "app_roles_admin_update" ON public.app_roles
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "app_roles_admin_delete" ON public.app_roles
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- ── Helper: is_admin() ──────────────────────────────────────────────────────
-- SECURITY DEFINER so it can read app_roles regardless of caller's own
-- RLS (which forbids non-admins from reading the table).
-- search_path locked to public + pg_temp to block search-path hijacking.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_roles
    WHERE user_id = auth.uid()
      AND role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ── Bootstrap the two current admins from the existing client allowlist ────
-- (admin-web/src/lib/supabase.ts: pak.zakn@gmail.com, zaid_azam@zeir.io)
-- Idempotent — re-running is safe.
INSERT INTO public.app_roles (user_id, role)
SELECT id, 'admin'
FROM auth.users
WHERE lower(email) IN ('pak.zakn@gmail.com', 'zaid_azam@zeir.io')
ON CONFLICT (user_id) DO NOTHING;

-- ── Verify ──────────────────────────────────────────────────────────────────
SELECT 'app_roles table' AS object,
       (SELECT count(*) FROM information_schema.tables
        WHERE table_schema='public' AND table_name='app_roles') AS exists;

SELECT 'is_admin() function' AS object,
       (SELECT count(*) FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname='public' AND p.proname='is_admin') AS exists;

SELECT 'admins bootstrapped' AS object,
       (SELECT count(*) FROM public.app_roles WHERE role='admin') AS count;
