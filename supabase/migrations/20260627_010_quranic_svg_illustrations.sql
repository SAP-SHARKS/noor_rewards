-- ─────────────────────────────────────────────────────────────────────────────
-- 20260627_010_quranic_svg_illustrations.sql
--
-- Wires the 15 Quranic-supplication SVGs (assets/illustrations/quranic/N.svg)
-- through the existing animation catalog:
--   1. Insert one `azkar_animations` row per SVG (key = quranic_svg_<n>)
--   2. Insert one `azkar_item_animations` junction row per Quranic supplication
--      at sort_order N (1, 2, 4, 7, 8, 11, 15, 16, 19, 21, 23, 24, 25, 36, 42).
--
-- Flutter side (`_buildIllustration` in dhikr_screen.dart) renders
-- `_QuranicSvgIllustration` whenever the resolved key starts with
-- `quranic_svg_`, so no Dart-side case enumeration is needed.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Catalog the 15 SVG keys ────────────────────────────────────────────
WITH supplied(pos) AS (
  VALUES (1),(2),(4),(7),(8),(11),(15),(16),(19),(21),(23),(24),(25),(36),(42)
)
INSERT INTO azkar_animations (key, name, description, is_active, sort_order)
SELECT
  'quranic_svg_' || pos,
  'Quranic supplication ' || pos,
  'Hand-drawn SVG illustration for Quranic supplication #' || pos,
  true,
  pos
FROM supplied
ON CONFLICT (key) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = true,
      updated_at  = now();


-- ── 2. Junction: link each supplication to its SVG ────────────────────────
WITH supplied(pos) AS (
  VALUES (1),(2),(4),(7),(8),(11),(15),(16),(19),(21),(23),(24),(25),(36),(42)
),
target_items AS (
  SELECT
    ai.id            AS azkar_id,
    ai.sort_order    AS pos,
    aa.id            AS animation_id
  FROM azkar_items ai
  JOIN azkar_item_categories ic ON ic.azkar_id = ai.id
  JOIN azkar_animations aa      ON aa.key      = 'quranic_svg_' || ai.sort_order
  WHERE ic.category_id = 'quranic_duas'
    AND ai.sort_order IN (SELECT pos FROM supplied)
)
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT azkar_id, animation_id, 100, pos FROM target_items
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- ── 3. Verify — should return 15 rows ─────────────────────────────────────
WITH supplied(pos) AS (
  VALUES (1),(2),(4),(7),(8),(11),(15),(16),(19),(21),(23),(24),(25),(36),(42)
)
SELECT
  ai.sort_order   AS svg_position,
  aa.key          AS animation_key,
  ai.id           AS azkar_id,
  ai.arabic       AS preview
FROM azkar_items ai
JOIN azkar_item_categories ic ON ic.azkar_id = ai.id
JOIN azkar_item_animations  aia ON aia.azkar_id = ai.id
JOIN azkar_animations       aa ON aa.id = aia.animation_id
WHERE ic.category_id = 'quranic_duas'
  AND ai.sort_order IN (SELECT pos FROM supplied)
  AND aa.key LIKE 'quranic_svg_%'
ORDER BY ai.sort_order;
