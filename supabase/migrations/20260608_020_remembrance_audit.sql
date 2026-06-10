-- =============================================================================
-- 20260608_020_remembrance_audit
--
-- Final illustration audit for Remembrance of Allah (dhikr_028-032).
-- Ruquiya is already correctly mapped (afiyah_guard / vessels / shield —
-- all M/E illustrations thematically aligned), so no changes there.
--
-- Changes:
--   • dhikr_028 (SubhanAllah wa bihamdihi): keep `ocean` (matches M/E
--     morning_32 / evening_31)
--   • dhikr_029 (Allahumma innaka 'afuwwun, Laylatul Qadr): switch from
--     `gates` (not actively in M/E pool) to `doors` (istighfar match,
--     M/E from morning_26 / evening_26)
--   • dhikr_030 (La hawla wa la quwwata): new text card — "Treasure of
--     Paradise" hadith has no direct M/E illustration match
--   • dhikr_031 (4 most beloved phrases): keep `glory` (M/E for
--     SubhanAllah/Alhamdulillah/Allahu Akbar tasbih)
--   • dhikr_032 (Dua of Yunus, Dhun-Nun): new text card — Yunus's
--     specific dua of distress doesn't fit a generic M/E illustration
-- =============================================================================

BEGIN;

-- 1. Register new text-card keys
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_dhikr_030', 'Dhikr · Treasure of Paradise', 'Text card: La hawla wa la quwwata illa billah — treasure of Jannah', '💎', 600),
  ('benefit_dhikr_032', 'Dhikr · Dhun-Nun (Yunus)',     'Text card: Dua of Yunus in the belly of the whale',                  '🌊', 601)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;

-- 2. Wipe existing mappings for the dhikr items we're touching
DELETE FROM azkar_item_animations
WHERE azkar_id IN ('dhikr_028', 'dhikr_029', 'dhikr_030', 'dhikr_031', 'dhikr_032');

-- 3. Re-insert audited mappings
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, 0
FROM (VALUES
  ('dhikr_028', 'ocean'),              -- SubhanAllah wa bihamdihi (keep)
  ('dhikr_029', 'doors'),              -- Laylatul Qadr istighfar (was gates)
  ('dhikr_030', 'benefit_dhikr_030'),  -- La hawla wa la quwwata (new text)
  ('dhikr_031', 'glory'),              -- 4 beloved phrases (keep)
  ('dhikr_032', 'benefit_dhikr_032')   -- Dua of Yunus (new text)
) AS m(azkar_id, anim_key)
JOIN azkar_animations a ON a.key = m.anim_key;

-- 4. Verify Remembrance + Ruquiya mappings
SELECT ai.id, ai.title, a.key AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.category_id IN ('remembrance_of_allah', 'ruquiya')
ORDER BY ai.category_id, ai.sort_order, aia.sort_order;

COMMIT;
