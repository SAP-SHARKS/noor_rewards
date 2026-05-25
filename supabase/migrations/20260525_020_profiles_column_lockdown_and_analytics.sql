-- =============================================================================
-- 20260525_020_profiles_column_lockdown_and_analytics
--
-- Fixes audit-final.md F-14 (profile mass-assignment) and F-16 (analytics
-- view exposure), confirmed by live-DB inspection 2026-05-25.
--
-- (A) profiles: row-level RLS already restricts UPDATE to the caller's own
--     row, but it does NOT restrict WHICH columns can be updated. So any
--     authenticated user could `UPDATE profiles SET noor_points = 999999`
--     directly from REST and pump their own Seeds balance.
--
--     Fix: revoke wide INSERT/UPDATE from authenticated, then grant only
--     the 6 safe profile-editing columns the Flutter client legitimately
--     writes from `profile_setup_screen.dart`, `profile_settings_screen.dart`,
--     and `main.dart` AuthGate. SECURITY DEFINER RPCs (`earn_xp`,
--     `sponsor_orphan`, `link_qf_profile`, the stats family) keep working
--     because they run as `postgres` and bypass column-level grants.
--
-- (B) analytics_country_summary / analytics_device_summary are VIEWS with no
--     RLS, currently SELECT-able by any authenticated user. Switch to
--     `security_invoker = true` (PG15+) so the views respect the caller's
--     RLS on the underlying tables. Combined with admin-gated policies on
--     those tables (or, in the worst case, restricting non-admins to
--     seeing only their own slice of telemetry — still much better than
--     full-table reads).
-- =============================================================================

-- ── (A) profiles: column-level write lockdown ──────────────────────────────

-- Revoke broad INSERT/UPDATE from the authenticated role; we'll re-grant
-- only the safe columns below.
REVOKE INSERT, UPDATE ON public.profiles FROM authenticated;

-- Allow inserting only the columns Flutter legitimately writes when a new
-- profile is being created (signup / QF link / profile setup).
GRANT INSERT (
  id,
  email,
  display_name,
  country,
  goals,
  setup_done,
  avatar_url
) ON public.profiles TO authenticated;

-- Allow updating only the columns the user can legitimately edit from
-- profile-settings / profile-setup. Anything missing from this list (e.g.
-- noor_points, total_xp, level, day_streak, ayahs_read, dhikr_count,
-- *_streak columns, referral_code, referred_by) is now write-locked from
-- the client and can only change via the SECURITY DEFINER RPCs.
GRANT UPDATE (
  display_name,
  country,
  city,
  goals,
  setup_done,
  avatar_url,
  avatar_color,
  mosque_team
) ON public.profiles TO authenticated;

-- SELECT continues unchanged (own-row policy + admin-read policy already
-- in place per pg_policies inspection).


-- ── (B) Analytics views: security_invoker ──────────────────────────────────
-- After this, a non-admin SELECT against the view will respect that user's
-- RLS on the underlying tables — typically returning only their own slice
-- of telemetry rather than every user's geography/device.
ALTER VIEW public.analytics_country_summary SET (security_invoker = true);
ALTER VIEW public.analytics_device_summary  SET (security_invoker = true);


-- ── Verify ─────────────────────────────────────────────────────────────────
-- After running, the profiles privileges output should show INSERT/UPDATE
-- only on the listed columns for the authenticated grantee:
SELECT grantee, privilege_type, column_name
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND grantee = 'authenticated'
  AND privilege_type IN ('INSERT', 'UPDATE')
ORDER BY privilege_type, column_name;

-- Views should now report security_invoker = true:
SELECT relname, reloptions
FROM pg_class
WHERE relname IN ('analytics_country_summary', 'analytics_device_summary');
