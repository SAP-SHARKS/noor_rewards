-- =============================================================================
-- 20260605_030_azkar_sleep_mulk_text_fix
--
-- Small follow-up to 20260605_020. The `benefit_sleep_mulk` card had an
-- incomplete benefit phrase; per user direction, sleep_before_020
-- (Surah Al-Mulk) should reuse the same hadith framing as sleep_before_019
-- (Surah As-Sajda). The Tirmidhi 2892 hadith actually pairs both surahs
-- as the Prophet's ﷺ nightly recitation before sleep, so this is also
-- more textually accurate.
--
-- Action:
--   1. Repoint sleep_before_020 from `benefit_sleep_mulk` to
--      `benefit_sleep_sajda` (the existing card already worded
--      correctly).
--   2. Remove the now-unused `benefit_sleep_mulk` key so it doesn't
--      clutter the admin animation picker. The ON DELETE CASCADE on
--      azkar_item_animations.animation_id ensures no orphan rows.
--
-- Idempotent: re-runnable.
-- =============================================================================

BEGIN;

-- 1. Remap sleep_before_020 to the As-Sajda text card ---------------------
DELETE FROM azkar_item_animations WHERE azkar_id = 'sleep_before_020';

INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT 'sleep_before_020', a.id, 1, 0
FROM azkar_animations a
WHERE a.key = 'benefit_sleep_sajda';

-- 2. Drop the unused mulk key from the catalog ----------------------------
DELETE FROM azkar_animations WHERE key = 'benefit_sleep_mulk';

-- 3. Verify ---------------------------------------------------------------
SELECT
  ai.id      AS azkar_id,
  ai.title,
  a.key      AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.id IN ('sleep_before_019', 'sleep_before_020')
ORDER BY ai.id;

COMMIT;
