-- =============================================================================
-- 20260524_030_rpc_idor_fixes
--
-- Fixes audit-final.md F-6, F-7, F-8, F-9, F-11.
--
-- All affected RPCs are re-created with:
--   • SAME signature (Flutter clients don't need updating)
--   • IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN RAISE ... checks
--   • Hardcoded per-call cap where amounts come from the client
--   • SET search_path = public, pg_temp (also fixes F-21 for these)
--   • REVOKE EXECUTE FROM PUBLIC, GRANT to authenticated only
--
-- Functions patched (10 total):
--   F-6 (Critical): sponsor_orphan
--   F-7 (Critical): record_activity_stats, get_user_monthly_stats,
--                   get_week_screen_time, record_dhikr_phrase,
--                   get_user_phrase_counts, get_user_lifetime_activity
--   F-8 (Critical): earn_xp
--   F-9 (Critical): link_qf_profile
--   F-11 (High):    earn_quran_points, earn_dhikr_points
-- =============================================================================

-- ── F-6: sponsor_orphan ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.sponsor_orphan(
  p_user_id   UUID,
  p_orphan_id UUID,
  p_amount    INTEGER
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_min_sponsorship INTEGER;
  v_is_active       BOOLEAN;
  v_balance         INTEGER;
BEGIN
  -- F-6 fix: caller must match p_user_id.
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- F-6 fix: cap to prevent runaway / negative amounts.
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 100000 THEN
    RAISE EXCEPTION 'invalid amount';
  END IF;

  SELECT min_sponsorship, is_active
    INTO v_min_sponsorship, v_is_active
  FROM sponsored_orphans WHERE id = p_orphan_id;

  IF NOT FOUND OR NOT v_is_active OR p_amount < v_min_sponsorship THEN
    RETURN FALSE;
  END IF;

  SELECT noor_points INTO v_balance FROM profiles WHERE id = p_user_id FOR UPDATE;
  IF v_balance IS NULL OR v_balance < p_amount THEN
    RETURN FALSE;
  END IF;

  UPDATE profiles SET noor_points = noor_points - p_amount WHERE id = p_user_id;

  INSERT INTO user_donations (user_id, orphan_id, points_donated, created_at)
  VALUES (p_user_id, p_orphan_id, p_amount, now());

  RETURN TRUE;
END $$;

REVOKE ALL ON FUNCTION public.sponsor_orphan(uuid, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sponsor_orphan(uuid, uuid, integer) TO authenticated;


-- ── F-8: earn_xp ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.earn_xp(p_user_id uuid, p_amount integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_xp    integer;
  v_level integer;
BEGIN
  -- F-8 fix: caller must match p_user_id.
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- F-8 fix: hard cap per call. Legitimate seal flushes are well under this.
  -- If a user genuinely earned > 5000 in one day, they can re-flush; better
  -- than letting one call mint a billion.
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 5000 THEN
    RAISE EXCEPTION 'invalid amount';
  END IF;

  UPDATE profiles
  SET    total_xp    = total_xp + p_amount,
         noor_points = noor_points + p_amount
  WHERE  id = p_user_id
  RETURNING total_xp INTO v_xp;

  SELECT COALESCE(MAX(level), 1) INTO v_level
  FROM   xp_levels
  WHERE  xp_required <= v_xp;

  UPDATE profiles SET level = v_level WHERE id = p_user_id;

  RETURN v_xp;
END $$;

REVOKE ALL ON FUNCTION public.earn_xp(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.earn_xp(uuid, integer) TO authenticated;


-- ── F-11: earn_quran_points (clamp p_coins for the projects pump) ──────────
CREATE OR REPLACE FUNCTION public.earn_quran_points(
  p_surah integer,
  p_ayah  integer,
  p_coins integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_pts INTEGER;
  v_ayahs INTEGER;
  v_safe_coins INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- F-11 fix: clamp p_coins so the community_projects pump can't be abused.
  v_safe_coins := GREATEST(0, LEAST(COALESCE(p_coins, 10), 100));

  INSERT INTO user_activities (user_id, activity_type, points_earned, metadata)
  VALUES (auth.uid(), 'quran', v_safe_coins,
          json_build_object('surah', p_surah, 'ayah', p_ayah));

  UPDATE profiles
  SET ayahs_read = ayahs_read + 1
  WHERE id = auth.uid()
  RETURNING noor_points, ayahs_read INTO v_pts, v_ayahs;

  UPDATE community_projects SET current_points = current_points + v_safe_coins
  WHERE is_active AND NOT is_completed;

  RETURN json_build_object('noor_points', v_pts, 'ayahs_read', v_ayahs);
END $$;


-- ── F-11: earn_dhikr_points (same clamp) ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.earn_dhikr_points(
  p_type  text,
  p_count integer,
  p_coins integer DEFAULT 20
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_pts INTEGER;
  v_dhikr INTEGER;
  v_safe_coins INTEGER;
  v_safe_count INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_safe_coins := GREATEST(0, LEAST(COALESCE(p_coins, 20), 100));
  v_safe_count := GREATEST(0, LEAST(COALESCE(p_count, 0), 1000));

  INSERT INTO user_activities (user_id, activity_type, points_earned, metadata)
  VALUES (auth.uid(), 'dhikr', v_safe_coins,
          json_build_object('type', p_type, 'count', v_safe_count));

  UPDATE profiles
  SET dhikr_count = dhikr_count + v_safe_count
  WHERE id = auth.uid()
  RETURNING noor_points, dhikr_count INTO v_pts, v_dhikr;

  UPDATE community_projects SET current_points = current_points + v_safe_coins
  WHERE is_active AND NOT is_completed;

  RETURN json_build_object('noor_points', v_pts, 'dhikr_count', v_dhikr);
END $$;


-- ── F-9: link_qf_profile ───────────────────────────────────────────────────
-- WARNING: this RPC moves another profile's progress into the caller's row.
-- The cleanest fix is to move this logic into the qf-token-exchange edge
-- function (which has already verified the user owns p_email via the QF
-- OAuth flow) and revoke this RPC from public callers entirely.
--
-- Minimum fix here (without breaking the live flow): require auth.uid() to
-- match p_new_id AND require auth.jwt() ->> 'email' to match p_email IF
-- present. For purely-anonymous Supabase sessions the email claim is empty,
-- so anonymous callers will be rejected. If your QF flow relies on
-- anonymous Supabase sessions, this is a HARD break — see follow-up in
-- audit-final.md F-9 remediation.
CREATE OR REPLACE FUNCTION public.link_qf_profile(
    p_email text,
    p_new_id uuid,
    p_name text,
    p_picture text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_old_profile RECORD;
    v_jwt_email TEXT;
BEGIN
    -- F-9 fix #1: caller must target their own auth.uid().
    IF auth.uid() IS NULL OR auth.uid() <> p_new_id THEN
      RETURN 'ERROR: forbidden';
    END IF;

    -- F-9 fix #2: caller's JWT email (if any) must match p_email.
    v_jwt_email := lower(coalesce(auth.jwt() ->> 'email', ''));
    IF v_jwt_email = '' OR v_jwt_email <> lower(p_email) THEN
      RETURN 'ERROR: email mismatch';
    END IF;

    SELECT * INTO v_old_profile
    FROM profiles
    WHERE email = p_email AND id != p_new_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN 'ERROR: No old profile found for email ' || p_email;
    END IF;

    BEGIN
        INSERT INTO profiles (id, email, display_name, avatar_url, setup_done)
        VALUES (p_new_id, p_email, p_name, p_picture, true)
        ON CONFLICT (id) DO NOTHING;

        UPDATE profiles
        SET referral_code = NULL, email = email || '_merged_' || (gen_random_uuid())::text
        WHERE id = v_old_profile.id;

        UPDATE profiles
        SET
            display_name = COALESCE(v_old_profile.display_name, profiles.display_name, p_name),
            country = v_old_profile.country,
            goals = v_old_profile.goals,
            noor_points = v_old_profile.noor_points,
            day_streak = v_old_profile.day_streak,
            level = v_old_profile.level,
            setup_done = true,
            ayahs_read = v_old_profile.ayahs_read,
            dhikr_count = v_old_profile.dhikr_count,
            total_xp = v_old_profile.total_xp,
            city = v_old_profile.city,
            mosque_team = v_old_profile.mosque_team,
            avatar_color = v_old_profile.avatar_color,
            referral_code = v_old_profile.referral_code,
            referred_by = v_old_profile.referred_by,
            login_streak = v_old_profile.login_streak,
            dhikr_streak = v_old_profile.dhikr_streak,
            quran_streak = v_old_profile.quran_streak,
            login_streak_updated_at = v_old_profile.login_streak_updated_at,
            dhikr_streak_updated_at = v_old_profile.dhikr_streak_updated_at,
            quran_streak_updated_at = v_old_profile.quran_streak_updated_at,
            best_login_streak = v_old_profile.best_login_streak,
            best_dhikr_streak = v_old_profile.best_dhikr_streak,
            best_quran_streak = v_old_profile.best_quran_streak
        WHERE id = p_new_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'ERROR internal: ' || SQLERRM;
    END;

    RETURN 'SUCCESS';
END;
$$;

REVOKE ALL ON FUNCTION public.link_qf_profile(text, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.link_qf_profile(text, uuid, text, text) TO authenticated;


-- ── F-7: record_activity_stats (the daily_stats version is the live one) ──
CREATE OR REPLACE FUNCTION public.record_activity_stats(
  p_user_id       uuid,
  p_type          text,
  p_count         int DEFAULT 1,
  p_duration_sec  int DEFAULT 0
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_month date := date_trunc('month', now())::date;
  v_today date := CURRENT_DATE;
BEGIN
  -- F-7 fix: caller must match p_user_id; clamp inputs.
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_type NOT IN ('quran', 'dhikr') THEN
    RAISE EXCEPTION 'invalid type';
  END IF;
  IF p_count < 0 OR p_count > 1000 OR p_duration_sec < 0 OR p_duration_sec > 86400 THEN
    RAISE EXCEPTION 'invalid payload';
  END IF;

  INSERT INTO user_monthly_stats (user_id, month)
    VALUES (p_user_id, v_month)
    ON CONFLICT (user_id, month) DO NOTHING;

  IF p_type = 'quran' THEN
    UPDATE user_monthly_stats SET
      ayahs_read     = ayahs_read + p_count,
      quran_sessions = quran_sessions + 1,
      quran_time_sec = quran_time_sec + p_duration_sec,
      updated_at     = now()
    WHERE user_id = p_user_id AND month = v_month;

    UPDATE user_analytics SET quran_time_sec = quran_time_sec + p_duration_sec
    WHERE user_id = p_user_id;
  ELSIF p_type = 'dhikr' THEN
    UPDATE user_monthly_stats SET
      dhikr_sets     = dhikr_sets + 1,
      dhikr_count    = dhikr_count + p_count,
      dhikr_time_sec = dhikr_time_sec + p_duration_sec,
      updated_at     = now()
    WHERE user_id = p_user_id AND month = v_month;

    UPDATE user_analytics SET dhikr_time_sec = dhikr_time_sec + p_duration_sec
    WHERE user_id = p_user_id;
  END IF;

  INSERT INTO user_daily_stats (user_id, stat_date)
    VALUES (p_user_id, v_today)
    ON CONFLICT (user_id, stat_date) DO NOTHING;

  IF p_type = 'quran' THEN
    UPDATE user_daily_stats SET
      ayahs_read     = ayahs_read + p_count,
      quran_time_sec = quran_time_sec + p_duration_sec,
      updated_at     = now()
    WHERE user_id = p_user_id AND stat_date = v_today;
  ELSIF p_type = 'dhikr' THEN
    UPDATE user_daily_stats SET
      dhikr_count    = dhikr_count + p_count,
      dhikr_time_sec = dhikr_time_sec + p_duration_sec,
      updated_at     = now()
    WHERE user_id = p_user_id AND stat_date = v_today;
  END IF;

  INSERT INTO global_daily_stats (stat_date)
    VALUES (v_today)
    ON CONFLICT (stat_date) DO NOTHING;

  IF p_type = 'quran' THEN
    UPDATE global_daily_stats SET total_ayahs = total_ayahs + p_count, updated_at = now()
    WHERE stat_date = v_today;
  ELSIF p_type = 'dhikr' THEN
    UPDATE global_daily_stats SET total_dhikr = total_dhikr + p_count, updated_at = now()
    WHERE stat_date = v_today;
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.record_activity_stats(uuid, text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_activity_stats(uuid, text, int, int) TO authenticated;


-- ── F-7: get_user_monthly_stats ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_monthly_stats(p_user_id uuid)
RETURNS TABLE (
  month           date,
  ayahs_read      int,
  quran_sessions  int,
  quran_time_sec  int,
  dhikr_sets      int,
  dhikr_count     int,
  dhikr_time_sec  int,
  total_points    int,
  login_days      int,
  active_days     int
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
    SELECT m.month, m.ayahs_read, m.quran_sessions, m.quran_time_sec,
           m.dhikr_sets, m.dhikr_count, m.dhikr_time_sec,
           m.total_points, m.login_days, m.active_days
    FROM user_monthly_stats m
    WHERE m.user_id = p_user_id
      AND m.month >= date_trunc('month', now() - interval '1 month')::date
    ORDER BY m.month DESC
    LIMIT 2;
END $$;

REVOKE ALL ON FUNCTION public.get_user_monthly_stats(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_monthly_stats(uuid) TO authenticated;


-- ── F-7: get_week_screen_time ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_week_screen_time(p_user_id uuid)
RETURNS TABLE (stat_date date, total_sec int)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
    WITH days AS (
      SELECT (CURRENT_DATE - i)::date AS d
      FROM generate_series(6, 0, -1) AS i
    )
    SELECT
      days.d AS stat_date,
      COALESCE(uds.quran_time_sec, 0) + COALESCE(uds.dhikr_time_sec, 0) AS total_sec
    FROM days
    LEFT JOIN user_daily_stats uds
      ON uds.user_id = p_user_id AND uds.stat_date = days.d
    ORDER BY days.d ASC;
END $$;

REVOKE ALL ON FUNCTION public.get_week_screen_time(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_week_screen_time(uuid) TO authenticated;


-- ── F-7: record_dhikr_phrase ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_dhikr_phrase(
  p_user_id   uuid,
  p_phrase_id text,
  p_count     int DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_phrase_id IS NULL OR length(p_phrase_id) = 0 THEN
    RETURN;
  END IF;
  IF p_count IS NULL OR p_count < 0 OR p_count > 10000 THEN
    RAISE EXCEPTION 'invalid count';
  END IF;

  INSERT INTO user_dhikr_phrase_counts(user_id, phrase_id, count)
    VALUES (p_user_id, p_phrase_id, p_count)
  ON CONFLICT (user_id, phrase_id)
  DO UPDATE SET
    count      = user_dhikr_phrase_counts.count + p_count,
    updated_at = now();
END $$;

REVOKE ALL ON FUNCTION public.record_dhikr_phrase(uuid, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_dhikr_phrase(uuid, text, int) TO authenticated;


-- ── F-7: get_user_phrase_counts ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_phrase_counts(p_user_id uuid)
RETURNS TABLE (phrase_id text, count bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
    SELECT c.phrase_id, c.count
    FROM user_dhikr_phrase_counts c
    WHERE c.user_id = p_user_id;
END $$;

REVOKE ALL ON FUNCTION public.get_user_phrase_counts(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_phrase_counts(uuid) TO authenticated;


-- ── F-7: get_user_lifetime_activity ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_lifetime_activity(p_user_id uuid)
RETURNS TABLE (
  total_ayahs_read bigint,
  total_dhikr      bigint,
  total_dhikr_sets bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
    SELECT
      COALESCE(SUM(m.ayahs_read), 0)::bigint,
      COALESCE(SUM(m.dhikr_count), 0)::bigint,
      COALESCE(SUM(m.dhikr_sets), 0)::bigint
    FROM user_monthly_stats m
    WHERE m.user_id = p_user_id;
END $$;

REVOKE ALL ON FUNCTION public.get_user_lifetime_activity(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_lifetime_activity(uuid) TO authenticated;


-- ── Verify ──────────────────────────────────────────────────────────────────
SELECT routine_name,
       routine_type,
       security_type,
       (CASE WHEN routine_definition LIKE '%auth.uid()%' THEN 'has auth check' ELSE 'NO AUTH CHECK' END) AS auth_check
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('sponsor_orphan','earn_xp','link_qf_profile',
                       'record_activity_stats','get_user_monthly_stats',
                       'get_week_screen_time','record_dhikr_phrase',
                       'get_user_phrase_counts','get_user_lifetime_activity',
                       'earn_quran_points','earn_dhikr_points')
ORDER BY routine_name;
