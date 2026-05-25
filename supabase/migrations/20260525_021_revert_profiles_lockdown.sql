-- =============================================================================
-- 20260525_021_revert_profiles_lockdown
--
-- Reverts the column-level lockdown from 20260525_020 — it broke the
-- profile-edit upsert because PostgREST requires table-level INSERT/UPDATE
-- before consulting column-level grants.
--
-- This restores the previous behaviour: any authenticated user can UPDATE
-- their own row (gated by the existing RLS `auth.uid() = id` policy), which
-- means they CAN still tamper with noor_points / total_xp / level via REST.
--
-- We will close that hole properly in a follow-up using a SECURITY DEFINER
-- `update_my_profile(...)` RPC (called from the client) + total revoke on
-- direct UPDATE. That change requires touching profile_settings_screen.dart
-- and profile_setup_screen.dart, so we will do it as a coordinated edit.
--
-- The analytics-view security_invoker change from 20260525_020 is NOT
-- reverted — it works correctly.
-- =============================================================================

GRANT INSERT, UPDATE ON public.profiles TO authenticated;

-- Verify privileges are restored. Should now show INSERT + UPDATE with no
-- column_name (i.e. full table).
SELECT grantee, privilege_type, column_name, is_grantable
FROM information_schema.column_privileges
WHERE table_schema='public' AND table_name='profiles' AND grantee='authenticated';

SELECT grantee, privilege_type
FROM information_schema.table_privileges
WHERE table_schema='public' AND table_name='profiles' AND grantee='authenticated';
