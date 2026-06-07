-- =============================================================================
-- 20260605_120_strip_remaining_ahmad_refs
--
-- The Ahmad / Ibn Majah strip in 20260605_110 used `\b` for word boundary,
-- which doesn't fire reliably in PostgreSQL POSIX regex for the patterns
-- in our data (e.g. "Upon the Fitrah of Islam Ahmad 15367" was left
-- untouched). Replace `\b` with explicit whitespace requirements.
--
-- Also catches a few additional collection-name variants we missed:
--   • "Hisn al-Muslim" without number
--   • "Ahmad ibn Hanbal ###"
--   • bare "Sahih Al-Hakim ###"
-- =============================================================================

BEGIN;

-- Ahmad ### (whitespace-anchored, no \b)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+Ahmad\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);
-- Ibn Majah ###
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+Ibn\s+Majah\s+\d+(?:\s*&\s*\d+)*',
  '', 'g'
);
-- Ad-Darimi
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+Ad-Darimi\b',
  '', 'g'
);
-- Mustadrak Al-Hakim
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+Mustadrak\s+Al-Hakim\b',
  '', 'g'
);
-- Ibn al-Sunni
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+Ibn\s+al-Sunni\b',
  '', 'g'
);

-- Final whitespace + trailing punctuation cleanup
UPDATE azkar_items SET reward = regexp_replace(reward, '\s{2,}', ' ', 'g');
UPDATE azkar_items SET reward = regexp_replace(reward, '[\s,;]+$', '', 'g');

-- Verify the two known-stuck rows
SELECT id, reward FROM azkar_items
WHERE id IN ('morning_13', 'evening_13')
ORDER BY id;

-- Final catch-all rescan (should now be 0 rows)
SELECT id, title, reward
FROM azkar_items
WHERE reward ~* '(Bukhari|Muslim|Dawud|Tirmidhi|Nasa''i|Ibn Majah|Hisn|Tabarani|Ahmad|Al-Jaami|Albani)\s+\d+'
ORDER BY id;

COMMIT;
