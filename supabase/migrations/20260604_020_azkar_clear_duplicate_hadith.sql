-- =============================================================================
-- 20260604_020_azkar_clear_duplicate_hadith
--
-- The screenshot-import migration (20260603_010) accidentally populated both
-- reward AND hadith_full with the same "Benefit" text. The detail card
-- renders both columns separately, so users see the benefit twice.
--
-- Fix: clear hadith_full where it duplicates reward, for the 6 new categories
-- only. Morning/Evening rows are untouched.
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET hadith_full = NULL
WHERE category_id IN (
        'duas_before_sleep', 'duas_after_salah', 'daily_duas',
        'remembrance_of_allah', 'rabbana_40', 'ruquiya'
      )
  AND hadith_full IS NOT NULL
  AND btrim(hadith_full) = btrim(COALESCE(reward, ''));

-- Verify: count of rows where reward and hadith_full now differ (or one is empty)
SELECT category_id,
       COUNT(*) FILTER (WHERE hadith_full IS NULL) AS hadith_cleared,
       COUNT(*) FILTER (WHERE hadith_full IS NOT NULL) AS hadith_kept
FROM azkar_items
WHERE category_id IN (
  'duas_before_sleep', 'duas_after_salah', 'daily_duas',
  'remembrance_of_allah', 'rabbana_40', 'ruquiya'
)
GROUP BY category_id
ORDER BY category_id;

COMMIT;
