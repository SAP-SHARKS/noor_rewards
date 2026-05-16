-- ============================================================================
-- Seal-credits-garden migration
--
-- Problem: earn_quran_points / earn_dhikr_points credited profiles.noor_points
-- (the "garden" / spendable Sabiq Seeds balance) the instant a user read an
-- ayah or finished dhikr. Sealing the day only ran earn_xp, which touched
-- total_xp — so the garden moved on *earn* and never on *seal*.
--
-- Fix: earned Seeds stay pending (tracked client-side) and are committed to
-- noor_points only when the user seals the day. The earn functions no longer
-- touch noor_points; earn_xp (called by the seal flush) now does.
--
-- Run this in Supabase SQL Editor.
-- ============================================================================

-- ── Quran: record the read, but do NOT credit Seeds here ────────────────────
CREATE OR REPLACE FUNCTION public.earn_quran_points(
  p_surah integer,
  p_ayah  integer,
  p_coins integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE v_pts INTEGER; v_ayahs INTEGER;
BEGIN
  INSERT INTO user_activities (user_id, activity_type, points_earned, metadata)
  VALUES (auth.uid(), 'quran', p_coins,
          json_build_object('surah', p_surah, 'ayah', p_ayah));

  -- Seeds are NOT credited here. They accumulate as pending and land in
  -- noor_points only when the user seals the day (see earn_xp).
  UPDATE profiles
  SET ayahs_read = ayahs_read + 1
  WHERE id = auth.uid()
  RETURNING noor_points, ayahs_read INTO v_pts, v_ayahs;

  UPDATE community_projects SET current_points = current_points + p_coins
  WHERE is_active AND NOT is_completed;

  RETURN json_build_object('noor_points', v_pts, 'ayahs_read', v_ayahs);
END;
$function$;

-- ── Dhikr: record the dhikr, but do NOT credit Seeds here ───────────────────
CREATE OR REPLACE FUNCTION public.earn_dhikr_points(
  p_type  text,
  p_count integer,
  p_coins integer DEFAULT 20
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE v_pts INTEGER; v_dhikr INTEGER;
BEGIN
  INSERT INTO user_activities (user_id, activity_type, points_earned, metadata)
  VALUES (auth.uid(), 'dhikr', p_coins,
          json_build_object('type', p_type, 'count', p_count));

  -- Seeds are NOT credited here — see earn_quran_points / earn_xp.
  UPDATE profiles
  SET dhikr_count = dhikr_count + p_count
  WHERE id = auth.uid()
  RETURNING noor_points, dhikr_count INTO v_pts, v_dhikr;

  UPDATE community_projects SET current_points = current_points + p_coins
  WHERE is_active AND NOT is_completed;

  RETURN json_build_object('noor_points', v_pts, 'dhikr_count', v_dhikr);
END;
$function$;

-- ── Seal: this is where earned Seeds actually land in the garden ────────────
-- earn_xp is called by the client's pending-flush when the user seals the
-- day, with the full flushed pending amount. It now credits both lifetime
-- XP and the spendable Seeds balance.
CREATE OR REPLACE FUNCTION public.earn_xp(p_user_id uuid, p_amount integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_xp    integer;
  v_level integer;
BEGIN
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
END;
$function$;
