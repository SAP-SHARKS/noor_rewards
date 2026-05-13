-- ============================================================================
-- Daily Worship-Time Stats Migration
-- Adds per-day screen time tracking so the Impact Report's Worship Activity
-- bar chart can show real per-day data and let users tap any day.
-- Run this in Supabase SQL Editor.
-- ============================================================================

-- 1. user_daily_stats — per-user per-day rollup of worship screen time
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_daily_stats (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_date       date NOT NULL DEFAULT CURRENT_DATE,

  quran_time_sec  int NOT NULL DEFAULT 0,
  dhikr_time_sec  int NOT NULL DEFAULT 0,
  ayahs_read      int NOT NULL DEFAULT 0,
  dhikr_count     int NOT NULL DEFAULT 0,

  updated_at      timestamptz NOT NULL DEFAULT now(),

  UNIQUE(user_id, stat_date)
);

ALTER TABLE user_daily_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own daily stats" ON user_daily_stats
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role manages daily stats" ON user_daily_stats
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX IF NOT EXISTS idx_uds_user_date
  ON user_daily_stats(user_id, stat_date DESC);


-- 2. Augment record_activity_stats to also write the daily rollup
-- ============================================================================
CREATE OR REPLACE FUNCTION record_activity_stats(
  p_user_id       uuid,
  p_type          text,
  p_count         int DEFAULT 1,
  p_duration_sec  int DEFAULT 0
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_month date := date_trunc('month', now())::date;
  v_today date := CURRENT_DATE;
BEGIN
  -- Monthly rollup (existing behavior)
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

  -- Daily rollup (new)
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

  -- Global daily counters (unchanged)
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


-- 3. get_week_screen_time — returns last 7 days (oldest → newest) for caller
-- ============================================================================
-- Returns an array of 7 rows, one per day from (today - 6) to today, with
-- total_sec = quran_time_sec + dhikr_time_sec. Missing days return 0.
-- Days are ordered Monday → Sunday based on the caller's locale; callers
-- can re-order client-side if a different week start is needed.
CREATE OR REPLACE FUNCTION get_week_screen_time(p_user_id uuid)
RETURNS TABLE (stat_date date, total_sec int)
LANGUAGE sql SECURITY DEFINER AS $$
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
$$;

GRANT EXECUTE ON FUNCTION get_week_screen_time(uuid) TO authenticated;
