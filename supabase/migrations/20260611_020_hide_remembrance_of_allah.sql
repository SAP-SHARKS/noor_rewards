-- =============================================================================
-- 20260611_020_hide_remembrance_of_allah
--
-- Hides the `remembrance_of_allah` category from the hub. The screenshot
-- import seeded it with items, but in practice it ended up as an empty
-- card in the UI and is now removed from the hub tile list (Flutter side).
-- We flip is_visible=false here too so any future DB-driven category
-- picker (admin panel, A/B switches, etc.) also drops it without needing
-- another code change.
--
-- Data is intentionally preserved (no DELETE) — if the category is ever
-- needed again we just set is_visible=true.
-- =============================================================================

BEGIN;

UPDATE azkar_categories
SET is_visible = false
WHERE id = 'remembrance_of_allah';

-- Verify
SELECT id, label, is_visible
FROM azkar_categories
WHERE id = 'remembrance_of_allah';

COMMIT;
