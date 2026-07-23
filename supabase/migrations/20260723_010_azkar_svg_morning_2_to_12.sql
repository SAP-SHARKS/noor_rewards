-- ─────────────────────────────────────────────────────────────────────────────
-- 20260723_010_azkar_svg_morning_2_to_12.sql
--
-- Adds hand-drawn SVG illustrations as ALTERNATIVES for Morning Azkar 2–12.
-- Existing animations stay linked; both entries form the daily-rotation pool
-- consumed by `_todayAnimationKeyFor` (pool[dayOfYear % pool.length]) in
-- dhikr_screen.dart. Same pattern as 20260719_010_azkar_svg_morning_1_fatihah.
--
-- Assets:     assets/illustrations/azkar/morning_<N>.svg
-- Anim keys:  azkar_svg_morning_<N>
-- Wired via:  dhikr_screen.dart routing — any key starting with
--             `azkar_svg_` loads from assets/illustrations/azkar/<rest>.svg
--             through the _QuranicSvgIllustration WebView renderer (which
--             already handles CSS/SMIL animation, gradient extraction, and
--             the light-gray fallback background you approved earlier).
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Register the 11 new animations in the catalog.
INSERT INTO azkar_animations (key, name, description, is_active, sort_order)
VALUES
  ('azkar_svg_morning_2',  'Morning 2 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #2.',  true, 2),
  ('azkar_svg_morning_3',  'Morning 3 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #3.',  true, 3),
  ('azkar_svg_morning_4',  'Morning 4 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #4.',  true, 4),
  ('azkar_svg_morning_5',  'Morning 5 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #5.',  true, 5),
  ('azkar_svg_morning_6',  'Morning 6 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #6.',  true, 6),
  ('azkar_svg_morning_7',  'Morning 7 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #7.',  true, 7),
  ('azkar_svg_morning_8',  'Morning 8 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #8.',  true, 8),
  ('azkar_svg_morning_9',  'Morning 9 (annotated SVG)',  'Hand-drawn illustration alternative for Morning Azkar #9.',  true, 9),
  ('azkar_svg_morning_10', 'Morning 10 (annotated SVG)', 'Hand-drawn illustration alternative for Morning Azkar #10.', true, 10),
  ('azkar_svg_morning_11', 'Morning 11 (annotated SVG)', 'Hand-drawn illustration alternative for Morning Azkar #11.', true, 11),
  ('azkar_svg_morning_12', 'Morning 12 (annotated SVG)', 'Hand-drawn illustration alternative for Morning Azkar #12.', true, 12)
ON CONFLICT (key) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = true,
      updated_at  = now();

-- 2. Link each new animation to its azkar as an alternative. Existing
--    animations stay linked (their sort_order = 0). New rows use
--    sort_order = 2 so the two pool entries stay ordered deterministically
--    across launches; dayOfYear-based rotation picks between them.
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT 'morning_2',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_2'
UNION ALL
SELECT 'morning_3',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_3'
UNION ALL
SELECT 'morning_4',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_4'
UNION ALL
SELECT 'morning_5',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_5'
UNION ALL
SELECT 'morning_6',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_6'
UNION ALL
SELECT 'morning_7',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_7'
UNION ALL
SELECT 'morning_8',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_8'
UNION ALL
SELECT 'morning_9',  aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_9'
UNION ALL
SELECT 'morning_10', aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_10'
UNION ALL
SELECT 'morning_11', aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_11'
UNION ALL
SELECT 'morning_12', aa.id, 100, 2 FROM azkar_animations aa WHERE aa.key = 'azkar_svg_morning_12'
ON CONFLICT (azkar_id, animation_id) DO NOTHING;

-- 3. Verify — should return one row per morning_2..morning_12 for the new SVGs
--    (in addition to whatever pre-existing animations were already there).
SELECT
  aia.azkar_id,
  aa.key,
  aia.sort_order,
  aa.is_active
FROM azkar_item_animations aia
JOIN azkar_animations aa ON aa.id = aia.animation_id
WHERE aia.azkar_id IN (
  'morning_2','morning_3','morning_4','morning_5','morning_6',
  'morning_7','morning_8','morning_9','morning_10','morning_11','morning_12'
)
ORDER BY aia.azkar_id, aia.sort_order;
