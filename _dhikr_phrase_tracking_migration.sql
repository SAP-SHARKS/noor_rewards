-- ============================================================================
-- Dhikr Phrase Tracking Migration
-- Adds per-phrase counters so Akhirah holdings (Trees, Treasures, Slaves Freed,
-- Sins Forgiven via "SubhanAllahi wa bihamdihi") can be computed from the
-- actual phrases the user recited, not from a fraction of total points.
--
-- Run this in Supabase SQL Editor.
-- ============================================================================

-- 1. Per-phrase lifetime counters
CREATE TABLE IF NOT EXISTS user_dhikr_phrase_counts (
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  phrase_id  text NOT NULL,
  count      bigint NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, phrase_id)
);

ALTER TABLE user_dhikr_phrase_counts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user reads own phrase counts" ON user_dhikr_phrase_counts;
CREATE POLICY "user reads own phrase counts" ON user_dhikr_phrase_counts
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "service role manages phrase counts" ON user_dhikr_phrase_counts;
CREATE POLICY "service role manages phrase counts" ON user_dhikr_phrase_counts
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX IF NOT EXISTS idx_udpc_user
  ON user_dhikr_phrase_counts(user_id);


-- 2. RPC to upsert a phrase count
CREATE OR REPLACE FUNCTION record_dhikr_phrase(
  p_user_id   uuid,
  p_phrase_id text,
  p_count     int DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_phrase_id IS NULL OR length(p_phrase_id) = 0 THEN
    RETURN;
  END IF;

  INSERT INTO user_dhikr_phrase_counts(user_id, phrase_id, count)
    VALUES (p_user_id, p_phrase_id, GREATEST(p_count, 0))
  ON CONFLICT (user_id, phrase_id)
  DO UPDATE SET
    count      = user_dhikr_phrase_counts.count + GREATEST(p_count, 0),
    updated_at = now();
END;
$$;


-- 3. RPC to load all phrase counts for the current user
CREATE OR REPLACE FUNCTION get_user_phrase_counts(p_user_id uuid)
RETURNS TABLE (phrase_id text, count bigint)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT phrase_id, count
  FROM user_dhikr_phrase_counts
  WHERE user_id = p_user_id;
$$;


-- 4. RPC to load lifetime activity totals (sum across all months)
CREATE OR REPLACE FUNCTION get_user_lifetime_activity(p_user_id uuid)
RETURNS TABLE (
  total_ayahs_read bigint,
  total_dhikr      bigint,
  total_dhikr_sets bigint
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    COALESCE(SUM(ayahs_read), 0)::bigint,
    COALESCE(SUM(dhikr_count), 0)::bigint,
    COALESCE(SUM(dhikr_sets), 0)::bigint
  FROM user_monthly_stats
  WHERE user_id = p_user_id;
$$;
