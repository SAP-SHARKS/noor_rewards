-- =============================================================================
-- 20260608_010_daily_dua_039_040_text_cards
--
-- User flagged display positions 34 and 35 in Daily Duas (= daily_dua_039
-- "Any Difficult Affairs" and daily_dua_040 "Anxiety and Sorrow") — both
-- were mapped to the `chains` M/E illustration. User prefers a dedicated
-- text card here instead. New keys registered + remapped accordingly.
-- =============================================================================

BEGIN;

-- Register the new text-card keys
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_daily_039', 'Daily · Make Difficult Easy', 'Text card: ask Allah to make the difficult easy',                 '🌿', 520),
  ('benefit_daily_040', 'Daily · Refuge from Burdens', 'Text card: refuge from worry, grief, weakness, debt, etc.',      '🛡️', 521)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;

-- Remap
DELETE FROM azkar_item_animations WHERE azkar_id IN ('daily_dua_039', 'daily_dua_040');

INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, 0
FROM (VALUES
  ('daily_dua_039', 'benefit_daily_039'),
  ('daily_dua_040', 'benefit_daily_040')
) AS m(azkar_id, anim_key)
JOIN azkar_animations a ON a.key = m.anim_key;

-- Verify
SELECT ai.id, ai.title, a.key AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.id IN ('daily_dua_039', 'daily_dua_040')
ORDER BY ai.id;

COMMIT;
