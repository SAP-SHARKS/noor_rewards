-- =============================================================================
-- 20260609_070_salah_006_007_remap
--
-- User flagged Duas after Salah items 5 and 6 (display positions) for
-- illustration mismatch:
--
--   • salah_after_006 (Tasbih 33+33+33+1) — Bukhari 6403 / Muslim 597a
--     hadith says "sins forgiven even if abundant as the foam of the
--     sea". That's exactly what `ocean` illustrates (used by morning_32
--     / evening_31). Drop `glory` + `scales` pool, use `ocean` as the
--     dedicated match.
--
--   • salah_after_007 (Tahlil 10x after Fajr/Maghrib) — Tirmidhi 3474
--     hadith: "equal to freeing four slaves, 10 hasanat, 10 sins erased,
--     10 ranks raised, security all day". No M/E illustration captures
--     these specific rewards — replace `scales` with new dedicated text
--     card `benefit_salah_freed_slaves`.
--
--   • salah_after_005 stays on `scales` (correct match for la ilaha
--     illallah unparalleled-reward phrase).
-- =============================================================================

BEGIN;

-- Register the new text-card key
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_salah_freed_slaves',
   'Salah · Freed Slaves',
   'Text card: 10x tahlil = freeing 4 slaves + hasanat + ranks',
   '🕊️', 700)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;

-- Remap 006 and 007
DELETE FROM azkar_item_animations WHERE azkar_id IN ('salah_after_006', 'salah_after_007');

INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, 0
FROM (VALUES
  ('salah_after_006', 'ocean'),                       -- sins forgiven like foam of sea
  ('salah_after_007', 'benefit_salah_freed_slaves')   -- 4 slaves + hasanat + ranks
) AS m(azkar_id, anim_key)
JOIN azkar_animations a ON a.key = m.anim_key;

-- Verify all 4-5-6 Duas after Salah
SELECT ai.id, ai.title, a.key AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.id IN ('salah_after_005', 'salah_after_006', 'salah_after_007')
ORDER BY ai.id;

COMMIT;
