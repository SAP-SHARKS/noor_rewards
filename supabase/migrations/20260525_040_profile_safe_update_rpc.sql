-- =============================================================================
-- 20260525_040_profile_safe_update_rpc
--
-- Fixes audit-final.md F-14 properly. The earlier attempt
-- (20260525_020) used column-level GRANT — PostgREST's upsert path can't
-- consult those, so it broke the profile-edit flow.
--
-- New approach: leave direct UPDATE/INSERT revoked from sensitive columns
-- and provide two SECURITY DEFINER RPCs that take only the columns the
-- client legitimately edits. The Flutter app will be updated in the same
-- commit to call these RPCs instead of `.from('profiles').upsert(...)`.
--
-- After this migration + the matching Flutter edits:
--   • Users cannot UPDATE noor_points / total_xp / level / streak / etc.
--     directly via REST (REVOKE'd from authenticated below).
--   • SECURITY DEFINER RPCs (earn_xp, sponsor_orphan, link_qf_profile,
--     stats family) keep working because they execute as postgres.
-- =============================================================================

-- ── Lock down direct writes ─────────────────────────────────────────────────
REVOKE INSERT, UPDATE, DELETE ON public.profiles FROM authenticated, anon;

-- (SELECT stays open under the existing per-row policy — admins can read
--  all rows; regular users can only read their own.)

-- ── RPC 1: update editable fields on caller's own profile ──────────────────
CREATE OR REPLACE FUNCTION public.update_my_profile(
  p_display_name TEXT DEFAULT NULL,
  p_country      TEXT DEFAULT NULL,
  p_city         TEXT DEFAULT NULL,
  p_goals        JSONB DEFAULT NULL,
  p_avatar_url   TEXT DEFAULT NULL,
  p_avatar_color TEXT DEFAULT NULL,
  p_mosque_team  TEXT DEFAULT NULL,
  p_setup_done   BOOLEAN DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;

  -- Light validation — bounds on a few free-text fields.
  IF p_display_name IS NOT NULL AND length(p_display_name) > 80 THEN
    RAISE EXCEPTION 'display_name too long';
  END IF;
  IF p_country IS NOT NULL AND length(p_country) > 80 THEN
    RAISE EXCEPTION 'country too long';
  END IF;

  UPDATE public.profiles SET
    display_name = COALESCE(p_display_name, display_name),
    country      = COALESCE(p_country,      country),
    city         = COALESCE(p_city,         city),
    goals        = COALESCE(p_goals,        goals),
    avatar_url   = COALESCE(p_avatar_url,   avatar_url),
    avatar_color = COALESCE(p_avatar_color, avatar_color),
    mosque_team  = COALESCE(p_mosque_team,  mosque_team),
    setup_done   = COALESCE(p_setup_done,   setup_done)
  WHERE id = auth.uid();
END $$;

REVOKE ALL ON FUNCTION public.update_my_profile(
  TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, BOOLEAN
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_my_profile(
  TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, BOOLEAN
) TO authenticated;

-- ── RPC 2: bootstrap a new profile row (signup / first AuthGate run) ───────
-- Same column allowlist as RPC 1, plus `email`. Insert-or-update so this
-- is the single safe replacement for the existing `.upsert(...)` calls.
CREATE OR REPLACE FUNCTION public.upsert_my_profile_bootstrap(
  p_email        TEXT DEFAULT NULL,
  p_display_name TEXT DEFAULT NULL,
  p_country      TEXT DEFAULT NULL,
  p_goals        JSONB DEFAULT NULL,
  p_avatar_url   TEXT DEFAULT NULL,
  p_setup_done   BOOLEAN DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;

  INSERT INTO public.profiles (id, email, display_name, country, goals, avatar_url, setup_done)
  VALUES (v_uid, p_email, p_display_name, p_country, p_goals, p_avatar_url, p_setup_done)
  ON CONFLICT (id) DO UPDATE SET
    email        = COALESCE(EXCLUDED.email,        public.profiles.email),
    display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name),
    country      = COALESCE(EXCLUDED.country,      public.profiles.country),
    goals        = COALESCE(EXCLUDED.goals,        public.profiles.goals),
    avatar_url   = COALESCE(EXCLUDED.avatar_url,   public.profiles.avatar_url),
    setup_done   = COALESCE(EXCLUDED.setup_done,   public.profiles.setup_done);
END $$;

REVOKE ALL ON FUNCTION public.upsert_my_profile_bootstrap(
  TEXT, TEXT, TEXT, JSONB, TEXT, BOOLEAN
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_my_profile_bootstrap(
  TEXT, TEXT, TEXT, JSONB, TEXT, BOOLEAN
) TO authenticated;
