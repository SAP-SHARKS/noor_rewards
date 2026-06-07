-- =============================================================================
-- 20260605_090_flatten_quote_artifacts
--
-- Final cleanup pass: 5 specific rows still display badly because the
-- imported hadith text used several layers of nested "quoted speech"
-- that lost its closing quotes when inline references were stripped.
-- Re-balancing those nested quotes by hand isn't worth the fragility —
-- removing the speech quotes entirely lets the narrative read as flat
-- prose, which is unambiguous and matches how most of the other
-- benefit texts already render.
--
-- Affected rows:
--   • daily_dua_012, daily_dua_013 (Entering / Leaving Masjid hadith)
--   • salah_after_010, salah_after_011 (Mu'awwidhatain hadith)
--   • sleep_before_010 (Al-Bara bedtime hadith)
--
-- Also collapses any ".  ." artifact left behind once the quote marks
-- are gone. Idempotent.
-- =============================================================================

BEGIN;

-- 1. Strip all literal " from the 5 problematic rows ----------------------
UPDATE azkar_items
SET reward = replace(reward, '"', '')
WHERE id IN (
  'daily_dua_012', 'daily_dua_013',
  'salah_after_010', 'salah_after_011',
  'sleep_before_010'
);

-- 2. Collapse any orphan ". . " left after the strip -----------------------
-- (e.g. salah_after_010 had `everything." . Narrated` → after step 1
-- becomes `everything.. Narrated`, which we want as `everything. Narrated`.)
UPDATE azkar_items SET reward = regexp_replace(reward, '\.\s*\.', '.', 'g');

-- 3. Whitespace + trailing punctuation cleanup -----------------------------
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');

-- 4. Verify ----------------------------------------------------------------
SELECT id, title, reward, length(reward) AS len
FROM azkar_items
WHERE id IN (
  'daily_dua_012', 'daily_dua_013',
  'salah_after_010', 'salah_after_011',
  'sleep_before_010'
)
ORDER BY id;

-- 5. Final diagnostic re-scan ---------------------------------------------
-- Should now return zero rows (or only short one-liners we want to keep).
SELECT
  ai.id, ai.category_id, ai.title, ai.reward, length(ai.reward) AS len
FROM azkar_items ai
WHERE ai.category_id NOT IN ('morning', 'evening')
  AND ai.reward IS NOT NULL
  AND ai.reward != ''
  AND length(ai.reward) >= 80
  AND (
    ai.reward !~ '[.!?"'']\s*$'
    OR ai.reward LIKE '%()%'
    OR ai.reward LIKE '%...%'
    OR (length(ai.reward) - length(replace(ai.reward, '"', ''))) % 2 = 1
  )
ORDER BY ai.category_id, ai.sort_order;

COMMIT;
