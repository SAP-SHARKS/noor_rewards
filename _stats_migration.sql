-- ============================================================================
-- Stats Tracking Migration
-- Run this in Supabase SQL Editor
-- ============================================================================

-- 1. User Monthly Stats — pre-aggregated per-user monthly rollups
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_monthly_stats (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month           date NOT NULL,  -- always 1st of month, e.g. '2026-05-01'

  -- Quran
  ayahs_read      int NOT NULL DEFAULT 0,
  quran_sessions  int NOT NULL DEFAULT 0,
  quran_time_sec  int NOT NULL DEFAULT 0,

  -- Dhikr / Dua & Azkar
  dhikr_sets      int NOT NULL DEFAULT 0,
  dhikr_count     int NOT NULL DEFAULT 0,
  dhikr_time_sec  int NOT NULL DEFAULT 0,

  -- General
  total_points    int NOT NULL DEFAULT 0,
  login_days      int NOT NULL DEFAULT 0,
  active_days     int NOT NULL DEFAULT 0,

  updated_at      timestamptz NOT NULL DEFAULT now(),

  UNIQUE(user_id, month)
);

ALTER TABLE user_monthly_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own stats" ON user_monthly_stats
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role manages stats" ON user_monthly_stats
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX IF NOT EXISTS idx_ums_user_month
  ON user_monthly_stats(user_id, month DESC);


-- 2. Global Daily Stats — community-wide daily counters
-- ============================================================================
CREATE TABLE IF NOT EXISTS global_daily_stats (
  stat_date       date PRIMARY KEY DEFAULT CURRENT_DATE,
  active_readers  int NOT NULL DEFAULT 0,
  active_dhikr    int NOT NULL DEFAULT 0,
  total_ayahs     int NOT NULL DEFAULT 0,
  total_dhikr     int NOT NULL DEFAULT 0,
  total_users     int NOT NULL DEFAULT 0,
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE global_daily_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read global stats" ON global_daily_stats
  FOR SELECT USING (true);

CREATE POLICY "Service role manages global stats" ON global_daily_stats
  FOR ALL USING (auth.role() = 'service_role');


-- 3. Augment user_analytics with category time columns
-- ============================================================================
ALTER TABLE user_analytics
  ADD COLUMN IF NOT EXISTS quran_time_sec int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS dhikr_time_sec int NOT NULL DEFAULT 0;


-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- 4. record_activity_stats — called after each Quran/Dhikr activity
-- ============================================================================
CREATE OR REPLACE FUNCTION record_activity_stats(
  p_user_id       uuid,
  p_type          text,            -- 'quran' | 'dhikr'
  p_count         int DEFAULT 1,   -- ayahs read OR dhikr reps
  p_duration_sec  int DEFAULT 0    -- time spent in this micro-session
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_month date := date_trunc('month', now())::date;
  v_today date := CURRENT_DATE;
BEGIN
  -- Ensure user_monthly_stats row exists
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

    -- All-time category time
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

  -- Upsert global daily stats
  INSERT INTO global_daily_stats (stat_date)
    VALUES (v_today)
    ON CONFLICT (stat_date) DO NOTHING;

  IF p_type = 'quran' THEN
    UPDATE global_daily_stats SET
      total_ayahs = total_ayahs + p_count,
      updated_at  = now()
    WHERE stat_date = v_today;
  ELSIF p_type = 'dhikr' THEN
    UPDATE global_daily_stats SET
      total_dhikr = total_dhikr + p_count,
      updated_at  = now()
    WHERE stat_date = v_today;
  END IF;
END;
$$;


-- 5. get_user_monthly_stats — fetch current + previous month
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_monthly_stats(p_user_id uuid)
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
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT month, ayahs_read, quran_sessions, quran_time_sec,
         dhikr_sets, dhikr_count, dhikr_time_sec,
         total_points, login_days, active_days
  FROM user_monthly_stats
  WHERE user_id = p_user_id
    AND month >= date_trunc('month', now() - interval '1 month')::date
  ORDER BY month DESC
  LIMIT 2;
$$;


-- 6. get_global_stats — community stats for today + month
-- ============================================================================
CREATE OR REPLACE FUNCTION get_global_stats()
RETURNS TABLE (
  today_readers     int,
  today_dhikr_users int,
  today_ayahs       int,
  today_total_dhikr int,
  today_active      int,
  month_total_ayahs bigint,
  month_total_dhikr bigint
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    COALESCE(d.active_readers, 0),
    COALESCE(d.active_dhikr, 0),
    COALESCE(d.total_ayahs, 0),
    COALESCE(d.total_dhikr, 0),
    COALESCE(d.total_users, 0),
    (SELECT COALESCE(SUM(ayahs_read), 0) FROM user_monthly_stats
     WHERE month = date_trunc('month', now())::date),
    (SELECT COALESCE(SUM(dhikr_count), 0) FROM user_monthly_stats
     WHERE month = date_trunc('month', now())::date)
  FROM global_daily_stats d
  WHERE d.stat_date = CURRENT_DATE;
$$;


-- 7. increment_global_active — bump daily active counters
-- ============================================================================
CREATE OR REPLACE FUNCTION increment_global_active(p_type text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_today date := CURRENT_DATE;
BEGIN
  INSERT INTO global_daily_stats (stat_date)
    VALUES (v_today) ON CONFLICT DO NOTHING;

  IF p_type = 'quran' THEN
    UPDATE global_daily_stats SET active_readers = active_readers + 1, updated_at = now()
    WHERE stat_date = v_today;
  ELSIF p_type = 'dhikr' THEN
    UPDATE global_daily_stats SET active_dhikr = active_dhikr + 1, updated_at = now()
    WHERE stat_date = v_today;
  ELSE
    UPDATE global_daily_stats SET total_users = total_users + 1, updated_at = now()
    WHERE stat_date = v_today;
  END IF;
END;
$$;


-- 8. sync_monthly_points — nightly cron to reconcile points/login from user_activities
-- ============================================================================
CREATE OR REPLACE FUNCTION sync_monthly_points()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_month date := date_trunc('month', now())::date;
BEGIN
  INSERT INTO user_monthly_stats (user_id, month, total_points, active_days, login_days)
    SELECT
      user_id,
      v_month,
      COALESCE(SUM(points_earned), 0),
      COUNT(DISTINCT created_at::date),
      COUNT(DISTINCT created_at::date) FILTER (WHERE activity_type = 'login')
    FROM user_activities
    WHERE created_at >= v_month
    GROUP BY user_id
  ON CONFLICT (user_id, month)
  DO UPDATE SET
    total_points = EXCLUDED.total_points,
    active_days  = EXCLUDED.active_days,
    login_days   = EXCLUDED.login_days,
    updated_at   = now();
END;
$$;
