-- =============================================================================
-- 20260607_010_salah_after_benefit_rewrite
--
-- User flagged items 9 and 10 in Duas after Salah as having "incomplete /
-- chopped" benefit text. Source screenshots for these items were not in
-- the captured set, so the rewrite uses authoritative Sahih translations
-- of the cited hadiths to produce clean, complete prose.
--
-- Items rewritten:
--   • salah_after_009 (Ayatul Kursi after every Fard prayer) — Abu Umamah
--     hadith via Sunan an-Nasa'i al-Kubra 9848 + Tabarani 7532
--   • salah_after_010 (Surah Al-Ikhlas 3× after Fajr/Maghrib) — Mu'adh
--     bin Abdullah bin Khubaib hadith via Jami at-Tirmidhi 3575 and Sunan
--     Abi Dawud 1523. Previous text had the "Have you prayed? Say. Say."
--     exchange clipped to a confusing "He said, Speak. He said, Say:".
--   • salah_after_011 (Surah Al-Falaq 3×) — same Mu'adh hadith, Falaq
--     emphasis.
--   • salah_after_012 (Surah An-Nas 3×) — same Mu'adh hadith, Nas
--     emphasis.
--
-- Reference field is NOT touched; the Reference section continues to cite
-- the original sources separately.
-- =============================================================================

BEGIN;

-- salah_after_009 ----------------------------------------------------------
UPDATE azkar_items
SET reward = 'It was narrated from Abu Umamah (RA) that the Messenger of Allah ﷺ said: "Whoever recites Ayat al-Kursi immediately after every obligatory prayer, nothing stands between him and his entry into Paradise except death." Recited once after each of the five daily prayers. Virtues of this verse include: it is the greatest verse of the Qur''an, it grants protection from the jinn, Shaytan flees from the home in which it is recited, and it contains the Greatest Name of Allah.'
WHERE id = 'salah_after_009';


-- salah_after_010 ----------------------------------------------------------
UPDATE azkar_items
SET reward = 'It was narrated from Mu''adh bin Abdullah bin Khubaib, from his father: We went out on a rainy and extremely dark night, looking for the Messenger of Allah ﷺ so that he could lead us in prayer. When we found him, he asked, "Have you prayed?" I did not answer. He said, "Say." I did not speak. He said again, "Say." I asked, "O Messenger of Allah, what shall I say?" He replied, "Say: Qul Huwa Allahu Ahad (Surah Al-Ikhlas) and the Mu''awwidhatayn — Al-Falaq and An-Nas — three times in the evening and three times in the morning, and they will suffice you against everything." It was also narrated from Uqbah ibn Amir that the Messenger of Allah ﷺ commanded him to recite the Mu''awwidhatayn after every prayer. The three Quls (Al-Ikhlas, Al-Falaq, An-Nas) are recited in Arabic after each obligatory prayer, with three repetitions after the Maghrib and Fajr prayers.'
WHERE id = 'salah_after_010';


-- salah_after_011 ----------------------------------------------------------
UPDATE azkar_items
SET reward = 'It was narrated from Mu''adh bin Abdullah bin Khubaib, from his father: We went out on a rainy and extremely dark night, looking for the Messenger of Allah ﷺ so that he could lead us in prayer. When we found him, he asked, "Have you prayed?" I did not answer. He said, "Say." I did not speak. He said again, "Say." I asked, "O Messenger of Allah, what shall I say?" He replied, "Say: Qul Huwa Allahu Ahad and the Mu''awwidhatayn — Al-Falaq and An-Nas — three times in the evening and three times in the morning, and they will suffice you against everything." Surah Al-Falaq is the second of the three Quls and one of the Mu''awwidhatayn (the two surahs of refuge). It is recited in Arabic after every obligatory prayer, with three repetitions after the Maghrib and Fajr prayers.'
WHERE id = 'salah_after_011';


-- salah_after_012 ----------------------------------------------------------
UPDATE azkar_items
SET reward = 'It was narrated from Mu''adh bin Abdullah bin Khubaib, from his father: We went out on a rainy and extremely dark night, looking for the Messenger of Allah ﷺ so that he could lead us in prayer. When we found him, he asked, "Have you prayed?" I did not answer. He said, "Say." I did not speak. He said again, "Say." I asked, "O Messenger of Allah, what shall I say?" He replied, "Say: Qul Huwa Allahu Ahad and the Mu''awwidhatayn — Al-Falaq and An-Nas — three times in the evening and three times in the morning, and they will suffice you against everything." Surah An-Nas is the third of the three Quls and the second of the Mu''awwidhatayn. It is recited in Arabic after every obligatory prayer, with three repetitions after the Maghrib and Fajr prayers.'
WHERE id = 'salah_after_012';


-- Verify ------------------------------------------------------------------
SELECT id, title, length(reward) AS len, reward
FROM azkar_items
WHERE id IN ('salah_after_009', 'salah_after_010', 'salah_after_011', 'salah_after_012')
ORDER BY id;

COMMIT;
