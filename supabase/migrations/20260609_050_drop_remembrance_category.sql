-- =============================================================================
-- 20260609_050_drop_remembrance_category
--
-- Standalone delete for the `remembrance_of_allah` category. The previous
-- migration (20260609_040_dhikrs_to_daily_duas) already includes this
-- delete, but if any leftover row blocked it, run this migration
-- separately. It also defensively reassigns any straggler azkar still
-- pointing at the category back to daily_duas before deleting.
-- =============================================================================

BEGIN;

-- Defensive: any item still bound to remembrance_of_allah goes to daily_duas
UPDATE azkar_items
SET category_id = 'daily_duas'
WHERE category_id = 'remembrance_of_allah';

-- Clean any straggler junction rows
DELETE FROM azkar_item_categories
WHERE category_id = 'remembrance_of_allah';

-- Drop the category
DELETE FROM azkar_categories WHERE id = 'remembrance_of_allah';

-- Verify category is gone + show daily_duas item count
SELECT 'category_check' AS what, COUNT(*) AS remaining
FROM azkar_categories WHERE id = 'remembrance_of_allah';

SELECT 'daily_duas_count' AS what, COUNT(*) AS total
FROM azkar_items WHERE category_id = 'daily_duas';

COMMIT;
