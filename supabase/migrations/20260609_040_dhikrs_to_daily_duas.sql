-- =============================================================================
-- 20260609_040_dhikrs_to_daily_duas
--
-- The source app ("Dua and Adhkar") keeps all 5 Dhikr items inside
-- Daily Duas at sort positions 28-32. Our app split them into a
-- separate "Remembrance of Allah" category, leaving Daily Duas with a
-- visible gap (27 → 33). Per user direction:
--
--   1. Restore dhikr_032 (Dua of Yunus) which was deleted in 20260609_030
--      based on an earlier display-bug observation; the source confirms
--      it exists.
--   2. Move dhikr_028..032 into the `daily_duas` category at sort
--      positions 28..32.
--   3. Delete the `remembrance_of_allah` category entirely (junction
--      rows are cleaned via existing CASCADE).
--   4. Re-add the `benefit_dhikr_032` animation mapping for dhikr_032.
--
-- Idempotent.
-- =============================================================================

BEGIN;

-- 1. Re-insert dhikr_032 (Dua of Yunus) ---------------------------------
INSERT INTO azkar_items (
  id, title, arabic, transliteration, translation,
  recommended_count, category_id, reward, reference, sort_order
) VALUES (
  'dhikr_032',
  'Dhikr 5 - One in Distress',
  'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
  'La ilaha illa anta subhaanaka inni kuntu minaz-zalimin.',
  'There is none worthy of worship except You, Glory to You, Indeed I have been of the transgressors.',
  1,
  'daily_duas',
  'Ibrahim bin Muhammad bin Sa''d (RA) narrated from his father, from Sa''d that the Messenger of Allah ﷺ said: The supplication of Dhun-Nun (Prophet Yunus) when he supplicated, while in the belly of the whale, was: La ilaha illa anta subhaanaka inni kuntu minaz-zalimin. So indeed, no Muslim man supplicates with it for anything, ever, except Allah responds to him.',
  'Jami at-Tirmidhi 3505',
  32
)
ON CONFLICT (id) DO UPDATE SET
  title             = EXCLUDED.title,
  arabic            = EXCLUDED.arabic,
  transliteration   = EXCLUDED.transliteration,
  translation       = EXCLUDED.translation,
  recommended_count = EXCLUDED.recommended_count,
  category_id       = EXCLUDED.category_id,
  reward            = EXCLUDED.reward,
  reference         = EXCLUDED.reference,
  sort_order        = EXCLUDED.sort_order;


-- 2. Reassign dhikr_028..032 to Daily Duas + set their sort positions
UPDATE azkar_items
SET category_id = 'daily_duas', sort_order = 28
WHERE id = 'dhikr_028';

UPDATE azkar_items
SET category_id = 'daily_duas', sort_order = 29
WHERE id = 'dhikr_029';

UPDATE azkar_items
SET category_id = 'daily_duas', sort_order = 30
WHERE id = 'dhikr_030';

UPDATE azkar_items
SET category_id = 'daily_duas', sort_order = 31
WHERE id = 'dhikr_031';

-- dhikr_032 already inserted with sort_order=32, category_id='daily_duas'


-- 3. Drop the old remembrance_of_allah junction rows + add daily_duas rows
DELETE FROM azkar_item_categories
WHERE azkar_id IN ('dhikr_028','dhikr_029','dhikr_030','dhikr_031','dhikr_032');

INSERT INTO azkar_item_categories (azkar_id, category_id, sort_order)
VALUES
  ('dhikr_028', 'daily_duas', 28),
  ('dhikr_029', 'daily_duas', 29),
  ('dhikr_030', 'daily_duas', 30),
  ('dhikr_031', 'daily_duas', 31),
  ('dhikr_032', 'daily_duas', 32)
ON CONFLICT (azkar_id, category_id) DO UPDATE SET
  sort_order = EXCLUDED.sort_order;


-- 4. Restore the benefit_dhikr_032 illustration mapping
DELETE FROM azkar_item_animations WHERE azkar_id = 'dhikr_032';

INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT 'dhikr_032', a.id, 1, 0
FROM azkar_animations a
WHERE a.key = 'benefit_dhikr_032';


-- 5. Delete the Remembrance of Allah category --------------------------
DELETE FROM azkar_categories WHERE id = 'remembrance_of_allah';


-- 6. Verify Daily Duas now has 44 items (was 39 + 5 new Dhikrs)
SELECT id, title, sort_order
FROM azkar_items
WHERE category_id = 'daily_duas'
ORDER BY sort_order, id;

-- Also confirm Remembrance is gone
SELECT id, label FROM azkar_categories
WHERE id = 'remembrance_of_allah';

COMMIT;
