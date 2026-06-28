-- ─────────────────────────────────────────────────────────────────────────────
-- 20260627_020_quranic_text_illustrations.sql
--
-- Text-based illustrations for the 27 Quranic supplications that don't have
-- an SVG yet. Same pattern as the SVG migration:
--   1. Insert one `azkar_animations` row per missing position
--      (key = quranic_text_<sort_order>).
--   2. Link each supplication via `azkar_item_animations`.
--
-- Flutter side (`_buildIllustration` in dhikr_screen.dart) short-circuits on
-- the `quranic_text_` prefix and renders `_QuranicTextIllustration`, which
-- cycles through 6 visual variants by position so adjacent supplications
-- look distinct.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Catalog the 27 text-variant keys ─────────────────────────────────
WITH missing(pos) AS (
  VALUES (3),(5),(6),(9),(10),(12),(13),(14),(17),(18),(20),(22),
         (26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(37),
         (38),(39),(40),(41)
)
INSERT INTO azkar_animations (key, name, description, is_active, sort_order)
SELECT
  'quranic_text_' || pos,
  'Quranic supplication ' || pos || ' (text)',
  'Animated text illustration for Quranic supplication #' || pos,
  true,
  pos
FROM missing
ON CONFLICT (key) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = true,
      updated_at  = now();


-- ── 2. Link each supplication to its text-variant animation ────────────
WITH missing(pos) AS (
  VALUES (3),(5),(6),(9),(10),(12),(13),(14),(17),(18),(20),(22),
         (26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(37),
         (38),(39),(40),(41)
),
target_items AS (
  SELECT
    ai.id            AS azkar_id,
    ai.sort_order    AS pos,
    aa.id            AS animation_id
  FROM azkar_items ai
  JOIN azkar_item_categories ic ON ic.azkar_id = ai.id
  JOIN azkar_animations aa      ON aa.key      = 'quranic_text_' || ai.sort_order
  WHERE ic.category_id = 'quranic_duas'
    AND ai.sort_order IN (SELECT pos FROM missing)
)
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT azkar_id, animation_id, 100, pos FROM target_items
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- ── 3. Verify — should return 27 rows ─────────────────────────────────
WITH missing(pos) AS (
  VALUES (3),(5),(6),(9),(10),(12),(13),(14),(17),(18),(20),(22),
         (26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(37),
         (38),(39),(40),(41)
)
SELECT
  ai.sort_order   AS position,
  aa.key          AS animation_key,
  ai.id           AS azkar_id
FROM azkar_items ai
JOIN azkar_item_categories ic ON ic.azkar_id = ai.id
JOIN azkar_item_animations  aia ON aia.azkar_id = ai.id
JOIN azkar_animations       aa ON aa.id = aia.animation_id
WHERE ic.category_id = 'quranic_duas'
  AND ai.sort_order IN (SELECT pos FROM missing)
  AND aa.key LIKE 'quranic_text_%'
ORDER BY ai.sort_order;
