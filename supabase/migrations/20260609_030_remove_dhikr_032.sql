-- =============================================================================
-- 20260609_030_remove_dhikr_032
--
-- Per user feedback, the 5th card in Remembrance of Allah (dhikr_032 —
-- the Dua of Yunus / Dhun-Nun in the belly of the whale) displays
-- empty in the app. Removing it from the dataset entirely. Foreign-key
-- CASCADE on azkar_item_animations and azkar_item_categories will clean
-- up the junction rows automatically.
--
-- After this, Remembrance of Allah will have 4 cards: dhikr_028 through
-- dhikr_031.
-- =============================================================================

BEGIN;

DELETE FROM azkar_items WHERE id = 'dhikr_032';

-- Verify remaining Remembrance items
SELECT id, title, sort_order
FROM azkar_items
WHERE category_id = 'remembrance_of_allah'
ORDER BY sort_order, id;

COMMIT;
