-- =============================================================================
-- 20260817_020_azkar_morning_33_salawat
--
-- Adds the Durood Ibrahim (Salawat) as morning position 33. Classical morning
-- azkar collections include the salawat 10× just like evening does, but our
-- current dataset only carried it as evening_32. Clone the same text into a
-- new row `morning_33` (independent id → independent completion counter) and
-- tag it into the `morning` category via the junction table.
--
-- Text is byte-identical to evening_32; we deliberately duplicate the row
-- rather than share it because the existing morning_31 / evening_30 pair
-- (Kalima) and morning_32 / evening_31 pair (Subhan Allah wa bihamdihi)
-- already follow that convention — completion is tracked per id, so users
-- do the morning session and evening session as separate acts.
--
-- Idempotent: ON CONFLICT DO UPDATE for the item, ON CONFLICT DO NOTHING for
-- the junction link. Safe to re-run.
-- =============================================================================

BEGIN;

INSERT INTO azkar_items (
  id, title, arabic, transliteration, translation,
  recommended_count, category_id, reward, reference, sort_order
) VALUES (
  'morning_33',
  'Durood Ibrahim',
  'اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَّعَلَىٰ اٰلِ مُحَمَّدٍ ، كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيْمَ وَعَلَىٰ اٰلِ إِبْرَاهِيْمَ ، إِنَّكَ حَمِيْدٌ مَّجِيْدٌ ، اَللّٰهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَّعَلَىٰ اٰلِ مُحَمَّدٍ ، كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيْمَ وَعَلَىٰ اٰلِ إِبْرَاهِيْمَ ، إِنَّكَ حَمِيْدٌ مَّجِيْدٌ.',
  'Allāhumma ṣalli ʿalā Muḥammad wa ʿalā āli Muḥammad, kamā ṣallayta ʿalā Ibrāhīma wa ʿalā āli Ibrāhīm, innaka Ḥamīdu-m-Majīd, Allāhumma bārik ʿalā Muḥammad, wa ʿalā āli Muḥammad, kamā bārakta ʿalā Ibrāhīma wa ʿalā āli Ibrāhīm, innaka Ḥamīdu-m-Majīd.',
  'O Allah, honour and have mercy upon Muhammad and the family of Muhammad as You have honoured and had mercy upon Ibrāhīm and the family of Ibrāhīm. Indeed, You are the Most Praiseworthy, the Most Glorious. O Allah, bless Muhammad and the family of Muhammad as You have blessed Ibrāhīm and the family of Ibrāhīm. Indeed, You are the Most Praiseworthy, the Most Glorious.',
  10,
  'morning',
  'Durood Ibrahim | Al-Bukhari 6357',
  'Al-Bukhari 6357',
  33
)
ON CONFLICT (id) DO UPDATE SET
  title             = EXCLUDED.title,
  arabic            = EXCLUDED.arabic,
  transliteration   = EXCLUDED.transliteration,
  translation       = EXCLUDED.translation,
  recommended_count = EXCLUDED.recommended_count,
  category_id       = EXCLUDED.category_id,
  reward            = EXCLUDED.reward,
  reference         = EXCLUDED.reference,
  sort_order        = EXCLUDED.sort_order;

-- Link the new item into the `morning` category via the junction table so it
-- appears alongside the other morning items even after the many-to-many
-- migration path. sort_order 33 mirrors the item's own sort_order.
INSERT INTO azkar_item_categories (azkar_id, category_id, sort_order)
VALUES ('morning_33', 'morning', 33)
ON CONFLICT (azkar_id, category_id) DO UPDATE SET sort_order = EXCLUDED.sort_order;

COMMIT;
