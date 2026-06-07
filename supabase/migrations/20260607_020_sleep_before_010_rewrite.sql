-- =============================================================================
-- 20260607_020_sleep_before_010_rewrite
--
-- Rewrites the Benefit text for sleep_before_010 (Prior to Sleeping 2,
-- Sahih al-Bukhari 6311) to match the source screenshot:
--
--   • Speech-quote structure restored ("Allah's Messenger said to me,
--     'When you want to go to bed…'"). The earlier flatten pass had
--     stripped these to fix unbalanced quote nesting, which left the
--     dialog reading as choppy prose.
--   • Transliteration typo fixed: "binabiyyik" → "binabiyyika".
--   • Hadith reference number kept in the reference field, NOT in the
--     reward text.
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET reward = 'Narrated Al-Bara bin Azib (RA): Allah''s Messenger ﷺ said to me, "When you want to go to bed, perform ablution as you do for prayer, then lie down on your right side and say: ''Allahumma aslamtu wajhi ilaika, wa fawwadtu ''amri ilaika, wa alja''tu dhahri ilaika, raghbatan wa rahbatan ilaika, la malja''a wa la manja minka illa ilaika. Amantu bikitabika al-ladhi anzalta wa binabiyyika al-ladhi arsalta.'' If you should die then (after reciting this) you will die on the religion of Islam — as a Muslim; so let these words be the last you say before going to bed." While I was memorising it, I said, "Wa birasulika al-ladhi arsalta (in Your Apostle whom You have sent)." The Prophet ﷺ said, "No, but say: Wa binabiyyika al-ladhi arsalta (in Your Prophet whom You have sent)."'
WHERE id = 'sleep_before_010';

-- Verify
SELECT id, title, length(reward) AS len, reward
FROM azkar_items
WHERE id = 'sleep_before_010';

COMMIT;
