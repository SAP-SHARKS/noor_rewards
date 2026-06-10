-- =============================================================================
-- 20260607_080_daily_dua_fixes_011_034
--
-- User feedback on the daily-dua audit:
--
--   • daily_dua_011 (Completion of Wudu): the `gates` illustration is
--     not currently used by any morning/evening azkar, so per the rule
--     ("only borrow from M/E"), we move 011 to `noor_door` — the same
--     illustration used by daily_dua_012 (Entering the Masjid) since
--     both depict a door / gate of mercy opening.
--   • daily_dua_034 (Hasbunallah wa ni'mal wakeel): replace `pillars`
--     (Hasbiyallah-specific M/E illustration) with a dedicated text card
--     `benefit_daily_034` because the dua phrasing here is different
--     (this is the Aali Imran 3:173 phrase, said by Ibrahim in the fire
--     and Muhammad ﷺ before battle — not the morning/evening
--     "Hasbiyallah" tasbih hadith).
-- =============================================================================

BEGIN;

-- Register the new text-card key
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_daily_034', 'Daily · Allah is Sufficient', 'Text card: Hasbunallah wa ni''mal wakeel (Aali Imran 3:173)', '🛡️', 519)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;

-- Remap daily_dua_011 and daily_dua_034
DELETE FROM azkar_item_animations WHERE azkar_id IN ('daily_dua_011', 'daily_dua_034');

INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, 0
FROM (VALUES
  ('daily_dua_011', 'noor_door'),         -- Completion of Wudu (was 'gates')
  ('daily_dua_034', 'benefit_daily_034')  -- Hasbunallah (was 'pillars')
) AS m(azkar_id, anim_key)
JOIN azkar_animations a ON a.key = m.anim_key;

-- Verify
SELECT
  ai.id, ai.title, a.key AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.id IN ('daily_dua_011', 'daily_dua_012', 'daily_dua_034', 'daily_dua_035')
ORDER BY ai.id;

COMMIT;
