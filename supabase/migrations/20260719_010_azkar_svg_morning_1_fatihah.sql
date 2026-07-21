-- ─────────────────────────────────────────────────────────────────────────────
-- 20260719_010_azkar_svg_morning_1_fatihah.sql
--
-- Adds a new hand-drawn Fatiha SVG as an ALTERNATIVE animation for the
-- morning Al-Fatiha entry (azkar_id = 'morning_1'). The existing animation
-- stays; both are added to the daily-rotation pool via
-- `_todayAnimationKeyFor` in dhikr_screen.dart (pool[dayOfYear % pool.length]).
--
-- Asset:      assets/illustrations/azkar/morning_1_fatihah.svg
-- Anim key:   azkar_svg_morning_1_fatihah
-- Wired via:  dhikr_screen.dart routing (`if ill.startsWith('azkar_svg_')`)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Register the new animation in the catalog.
INSERT INTO azkar_animations (key, name, description, is_active, sort_order)
VALUES (
  'azkar_svg_morning_1_fatihah',
  'Morning Al-Fatiha (annotated SVG)',
  'Hand-drawn annotated illustration for Surah Al-Fatiha in the Morning Azkar list.',
  true,
  1
)
ON CONFLICT (key) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = true,
      updated_at  = now();

-- 2. Link the animation to morning_1 as an alternative (the existing
--    animation stays — `ON CONFLICT DO NOTHING` is a no-op if already
--    linked, and both rows form the rotation pool).
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT 'morning_1', aa.id, 100, 2
FROM azkar_animations aa
WHERE aa.key = 'azkar_svg_morning_1_fatihah'
ON CONFLICT (azkar_id, animation_id) DO NOTHING;

-- 3. Verify — expect ≥ 2 rows for morning_1 after this migration.
SELECT
  aia.azkar_id,
  aa.key,
  aia.sort_order,
  aa.is_active
FROM azkar_item_animations aia
JOIN azkar_animations aa ON aa.id = aia.animation_id
WHERE aia.azkar_id = 'morning_1'
ORDER BY aia.sort_order;
