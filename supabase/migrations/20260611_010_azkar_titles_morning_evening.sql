-- =============================================================================
-- 20260611_010_azkar_titles_morning_evening
--
-- Fills the `title` column for well-known Morning/Evening azkar so the
-- Dua & Azkar list view can show recognizable names (e.g. "Ayatul Kursi",
-- "Surah Al-Ikhlas") instead of opening transliterations that all start
-- with "Bismillaahir Rahmaanir Raheem..." and read as identical to users.
--
-- Targets are matched by Arabic content so the migration is robust against
-- sequence-number drift across re-imports. Only rows that currently have
-- NULL or empty title are touched — never overwrite a manually set title.
--
-- The 6 screenshot-imported categories (duas_before_sleep, duas_after_salah,
-- daily_duas, remembrance_of_allah, rabbana_40, ruquiya) already have
-- titles populated from their CSV subtitle field; this only covers the
-- older morning / evening rows.
-- =============================================================================

BEGIN;

-- Ayatul Kursi — Al-Baqarah 2:255. Matched by the unique phrase
-- "الْحَىُّ الْقَيُّوْمُ" (the Ever-Living, the Sustainer).
UPDATE azkar_items SET title = 'Ayatul Kursi'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%الْقَيُّوْمُ%';

-- Surah Al-Ikhlas — recognized by its opening "Qul Huwallahu Ahad".
UPDATE azkar_items SET title = 'Surah Al-Ikhlas'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%قُلْ هُوَ اللهُ اَحَدٌ%';

-- Surah Al-Falaq — "Qul a'oodhu bi Rabbil-Falaq".
UPDATE azkar_items SET title = 'Surah Al-Falaq'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%قُلْ اَعُوْذُ بِرَبِّ الْفَلَقِ%';

-- Surah An-Nas — "Qul a'oodhu bi Rabbin-Naas".
UPDATE azkar_items SET title = 'Surah An-Nas'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%قُلْ اَعُوْذُ بِرَبِّ النَّاسِ%';

-- Last two ayahs of Al-Baqarah (Amana ar-Rasool, 285) — opens with
-- "Aamana ar-Rasoolu bimaa unzila".
UPDATE azkar_items SET title = 'Al-Baqarah 285 (Amana ar-Rasool)'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%اٰمَنَ الرَّسُوْلُ%';

-- Al-Baqarah 286 — "La yukallifullahu nafsan illa wus'aha".
UPDATE azkar_items SET title = 'Al-Baqarah 286'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%لَا يُكَلِّفُ اللّٰهُ نَفْسًا%';

-- Sayyid al-Istighfar (Master of Seeking Forgiveness) — recognized by
-- "Anta Rabbi" combined with "Aboo'u laka bi-ni'matika".
UPDATE azkar_items SET title = 'Sayyid al-Istighfar'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%أَنْتَ رَبِّيْ%'
  AND arabic LIKE '%أَبُوْءُ%';

-- Tasbih (33+33+33+1) — the common compound dhikr.
UPDATE azkar_items SET title = 'Tasbih: SubhanAllah, Alhamdulillah, Allahu Akbar'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%سُبْحَانَ اللهِ%'
  AND arabic LIKE '%اَلْحَمْدُ%'
  AND arabic LIKE '%اَللهُ اَكْبَرُ%';

-- Hasbunallahu wa ni'mal Wakeel (Allah suffices us) — well-known protection.
UPDATE azkar_items SET title = 'Hasbunallahu wa ni''mal Wakeel'
WHERE category_id IN ('morning', 'evening')
  AND (title IS NULL OR title = '')
  AND arabic LIKE '%حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيْلُ%';

-- Verify which rows were updated.
SELECT id, category_id, title
FROM azkar_items
WHERE category_id IN ('morning', 'evening')
  AND title IS NOT NULL
  AND title != ''
ORDER BY category_id, id;

COMMIT;
