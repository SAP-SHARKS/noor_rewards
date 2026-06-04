-- =============================================================================
-- 20260604_030_azkar_split_sections
--
-- Cleans English section labels ("Dua 1", "DUA QUNOOT 1", "After Takbir #1",
-- "SHORT:", "LONG:", "Repeat what the Mu'adhin says...") out of the Arabic
-- field on 5 Daily Duas rows. Each section becomes a phrase in the existing
-- phrases JSONB column (re-uses the Tasbih Fatima infrastructure from
-- 20260604_010). UI fades between phrases as the user taps.
--
--   daily_dua_009  After meals             -> 3 phrases (alternates), count = 3
--   daily_dua_014  Answering the Adhan     -> response-only, single phrase, count = 1
--   daily_dua_016  Dua Qunoot              -> 2 phrases (alternates), count = 2
--   daily_dua_017  Janaza Prayer           -> 4 phrases (sequential), count = 4
--   daily_dua_019  On Journey              -> 2 phrases (short / long), count = 2
-- =============================================================================

BEGIN;

-- ── 1. Daily #9 After meals (3 alternate duas) -----------------------------
UPDATE azkar_items
SET
  recommended_count = 3,
  recommended_count_label = NULL,
  arabic = 'اَلْحَمْدُ لِلّٰهِ',
  transliteration = 'Alhamdulillah',
  translation = 'Three alternate duas reported for after meals. Tap through to view each.',
  phrases = '[
    {"arabic": "اَلْحَمْدُ لِلّٰهِ الَّذِىْۤ اَطْعَمَنِىْ هٰذَا وَرَزَقَنِيْهِ مِنْ غَيْرِ حَوْلٍ مِّنِّيْ وَلَا قُوَّةٍ",
     "transliteration": "Alhamdulillahi hil-ladhee at''amanee haadha; Wa razaqaneehi min ghayri hawlin minnee wa laa quwwah.",
     "translation": "Praise is to Allah Who has given me this food, and sustained me with it though I was unable to do it and powerless.",
     "count": 1},
    {"arabic": "اَلْحَمْدُ لِلّٰهِ الَّذِىْۤ اَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِيْنَ",
     "transliteration": "Alhamdulillahi hil-ladhee at''aamana wa saqaana wa ja''alana Muslimeen.",
     "translation": "All praise belongs to Allah, who fed us and quenched our thirst and made us Muslims.",
     "count": 1},
    {"arabic": "اَللّٰهُمَّ بَارِكْ لَنَا فِيْهِ وَاَطْعِمْنَا خَيْرًا مِّنْهُ",
     "transliteration": "Allahumma baarik lanaa feehi wa at''imnaa khayran minhu.",
     "translation": "O Allah, bless us in it and feed us better than it.",
     "count": 1}
  ]'::jsonb
WHERE id = 'daily_dua_009';


-- ── 2. Daily #14 Answering the Adhan (response-only, no English) -----------
-- Original mixed Arabic + English instructions. Strip the guidance into
-- translation/benefit; keep only the actual Arabic response in arabic field.
UPDATE azkar_items
SET
  recommended_count = 1,
  recommended_count_label = NULL,
  arabic = 'لَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللهِ',
  transliteration = 'Laa hawla wa laa quwwata illa billaah',
  translation = E'Repeat each phrase of the Adhan after the Mu\'adhin, EXCEPT when he says ''Hayya ''alas-salaah'' (Hasten to the prayer) and ''Hayya ''alal-falaah'' (Hasten to real success) — for those two, respond instead with: ''Laa hawla wa laa quwwata illa billaah'' (There is no might nor power except with Allah).',
  phrases = NULL
WHERE id = 'daily_dua_014';


-- ── 3. Daily #16 Dua Qunoot (2 alternates) ---------------------------------
UPDATE azkar_items
SET
  recommended_count = 2,
  recommended_count_label = NULL,
  arabic = 'اَللّٰهُمَّ اهْدِنَا فِيْمَنْ هَدَيْتَ',
  transliteration = 'Dua Qunoot',
  translation = 'Two narrated versions of Dua Qunoot. Either may be recited in the witr prayer. Tap through to view each.',
  phrases = '[
    {"arabic": "اَللّٰهُمَّ اهْدِنَا فِيْمَنْ هَدَيْتَ، وَعَافِنَا فِيْمَنْ عَافَيْتَ، وَتَوَلَّنَا فِيْمَنْ تَوَلَّيْتَ، وَبَارِكْ لَنَا فِيْمَاۤ اَعْطَيْتَ، وَقِنَا شَرَّ مَا قَضَيْتَ، اِنَّكَ تَقْضِىْ وَلَا يُقْضٰى عَلَيْكَ، اِنَّهٗ لَا يَذِلُّ مَنْ وَّالَيْتَ، وَلَا يَعِزُّ مَنْ عَادَيْتَ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ",
     "transliteration": "Allahummahdinaa feeman hadayt; Wa aafinaa feeman aafayt; Wa tawallanaa feeman tawallayt; Wa baarik lanaa feema a''tayt; Wa qinaa sharra ma qadayt; Innaka taqdee wa laa yuqdaa ''alayk; Innahoo laa yadhillu man waalayt; Wa laa ya''izzu man ''aadayt; Tabaarakta Rabbanaa wa ta''aalayt.",
     "translation": "O Allah, guide us among those whom You have guided, pardon us among those whom You have pardoned, turn to us in friendship among those on whom You have turned in friendship, and bless us in what You have bestowed, and save us from the evil of what You have decreed.",
     "count": 1},
    {"arabic": "اَللّٰهُمَّ اِنَّا نَسْتَعِيْنُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِىْ عَلَيْكَ الْخَيْرَ، وَنَشْكُرُكَ وَلَا نَكْفُرُكَ، وَنَخْلَعُ وَنَتْرُكُ مَنْ يَّفْجُرُكَ. اَللّٰهُمَّ اِيَّاكَ نَعْبُدُ، وَلَكَ نُصَلِّىْ وَنَسْجُدُ، وَاِلَيْكَ نَسْعٰى وَنَحْفِدُ، نَرْجُوْا رَحْمَتَكَ، وَنَخْشٰى عَذَابَكَ، اِنَّ عَذَابَكَ بِالْكُفَّارِ مُلْحِقٌ",
     "transliteration": "Allahumma innaa nasta''eenuka, Wa nastaghfiruka, Wa nu''minu bika, Wa natawakkalu ''alayka, Wa nuthnee ''alaykal khayr; Wa nashkuruka wa laa nakfuruka, Wa nakhla''u wa natruku man yafjuruk.",
     "translation": "O Allah! We beg help from You alone; ask forgiveness from You alone, and turn towards You and have faith in You alone and we praise You for all the good things and are grateful to You and are not ungrateful to You.",
     "count": 1}
  ]'::jsonb
WHERE id = 'daily_dua_016';


-- ── 4. Daily #17 Janaza Prayer (4 sequential takbirs) ----------------------
UPDATE azkar_items
SET
  recommended_count = 4,
  recommended_count_label = NULL,
  arabic = 'سُبْحَانَكَ اَللّٰهُمَّ وَبِحَمْدِكَ',
  transliteration = 'Janaza Prayer — 4 Takbirs',
  translation = 'Funeral prayer. Recite each section after its corresponding Takbir.',
  phrases = '[
    {"arabic": "سُبْحَانَكَ اَللّٰهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالٰى جَدُّكَ، وَلَا اِلٰهَ غَيْرُكَ. ثُمَّ تَقْرَأُ سُوْرَةَ الْفَاتِحَةِ",
     "transliteration": "After Takbir #1 (Optional): Sub''haanaka Allahumma wa bi''hamdika; Wa tabaarakas''muka; Wa ta''aalaa jadduka; Wa laa ilaaha ghairuka — followed by Surah Al-Fatihah.",
     "translation": "Glory be to You O Allah, and praise be to You, and blessed is Your name, and exalted is Your Majesty, and there is none to be served besides You. Then recite Surah Al-Fatihah.",
     "count": 1},
    {"arabic": "اَللّٰهُمَّ صَلِّ عَلٰى مُحَمَّدٍ وَّعَلٰىۤ اٰلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلٰىۤ اِبْرَاهِيْمَ وَعَلٰىۤ اٰلِ اِبْرَاهِيْمَ، اِنَّكَ حَمِيْدٌ مَّجِيْدٌ. اَللّٰهُمَّ بَارِكْ عَلٰى مُحَمَّدٍ وَّعَلٰىۤ اٰلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلٰىۤ اِبْرَاهِيْمَ وَعَلٰىۤ اٰلِ اِبْرَاهِيْمَ، اِنَّكَ حَمِيْدٌ مَّجِيْدٌ",
     "transliteration": "After Takbir #2 — Salawat Ibrahim: Allaahumma salli ''ala Muhammad, Wa ''ala aali Muhammad, Kamaa sallayta ''ala Ibraaheem, Wa ''ala aali Ibraaheem, Innaka hameedum majeed. Allaahumma baarik ''ala Muhammad...",
     "translation": "O Allah, let Your Blessings come upon Muhammad and the family of Muhammad, as you have blessed Ibrahim and his family. Truly, You are Praiseworthy and Glorious.",
     "count": 1},
    {"arabic": "اَللّٰهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَشَاهِدِنَا وَغَائِبِنَا وَصَغِيْرِنَا وَكَبِيْرِنَا وَذَكَرِنَا وَاُنْثٰنَا. اَللّٰهُمَّ مَنْ اَحْيَيْتَهٗ مِنَّا فَاَحْيِهٖ عَلَى الْاِسْلَامِ، وَمَنْ تَوَفَّيْتَهٗ مِنَّا فَتَوَفَّهٗ عَلَى الْاِيْمَانِ. اَللّٰهُمَّ لَا تَحْرِمْنَا اَجْرَهٗ وَلَا تُضِلَّنَا بَعْدَهٗ",
     "transliteration": "After Takbir #3: Allahummaghfir li-hayyinaa wa mayyitinaa wa shaahidinaa wa ghaa''ibinaa wa sagheerinaa wa kabeerinaa wa dhakarinaa wa unthaanaa. Allahumma man ahyaitahu minna fa''ahyihi ''alal-Islaam, wa man tawaffaitahu minna fa tawaffahu ''alal-Eemaan. Allahumma laa tahrimna ajrahu wa laa tudilanaa ba''dah.",
     "translation": "O Allah, forgive our living and our dead, those present and those absent, our young and our old, our males and our females. O Allah, whom amongst us You keep alive, then let such a life be upon Islam, and whom amongst us You take unto Yourself, then let such a death be upon faith. O Allah, do not deprive us of his reward and do not let us stray after him.",
     "count": 1},
    {"arabic": "اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللهِ",
     "transliteration": "After Takbir #4 (Right side only): Assalaamu ''alaykum wa rahmatullah.",
     "translation": "Peace be upon you and the mercy of Allah. (Turn the head right and say the salam.)",
     "count": 1}
  ]'::jsonb
WHERE id = 'daily_dua_017';


-- ── 5. Daily #19 On Journey (short / long versions) -----------------------
UPDATE azkar_items
SET
  recommended_count = 2,
  recommended_count_label = NULL,
  arabic = 'سُبْحَانَ الَّذِىْ سَخَّرَ لَنَا هٰذَا',
  transliteration = 'On Journey — Short / Long',
  translation = 'Two narrated versions. Recite either when setting out on a journey.',
  phrases = '[
    {"arabic": "سُبْحَانَ الَّذِىْ سَخَّرَ لَنَا هٰذَا وَمَا كُنَّا لَهٗ مُقْرِنِيْنَ، وَاِنَّاۤ اِلٰى رَبِّنَا لَمُنْقَلِبُوْنَ",
     "transliteration": "Short version: Subhana lladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, Wa inna ila Rabbina lamunqalibun.",
     "translation": "Glory is to Him Who has provided this for us though we could never have had it by our efforts. Surely, unto our Lord, we are returning.",
     "count": 1},
    {"arabic": "بِسْمِ اللهِ، اَلْحَمْدُ لِلهِ، سُبْحَانَ الَّذِىْ سَخَّرَ لَنَا هٰذَا وَمَا كُنَّا لَهٗ مُقْرِنِيْنَ، وَاِنَّاۤ اِلٰى رَبِّنَا لَمُنْقَلِبُوْنَ. اَلْحَمْدُ لِلهِ، اَلْحَمْدُ لِلهِ، اَلْحَمْدُ لِلهِ، اَللهُ اَكْبَرُ، اَللهُ اَكْبَرُ، اَللهُ اَكْبَرُ، سُبْحَانَكَ اَللّٰهُمَّ اِنِّيْ ظَلَمْتُ نَفْسِيْ، فَاغْفِرْ لِيْ، فَاِنَّهٗ لَا يَغْفِرُ الذُّنُوْبَ اِلَّاۤ اَنْتَ",
     "transliteration": "Long version: Bismillah, Walhamdulillah. Subhana lladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, Wa inna ila Rabbina lamunqalibun. Alhamdulillah (×3), Allahu Akbar (×3), Subhanaka llahumma inni zalamtu nafsi, Faghfir li, Fa innahu la yaghfirudh-dhunooba illa ant.",
     "translation": "With the Name of Allah. Praise is to Allah. Glory is to Him Who has provided this for us. Praise is to Allah (×3). Allah is the Most Great (×3). Glory is to You. O Allah, I have wronged my own soul. Forgive me, for surely none forgives sins but You.",
     "count": 1}
  ]'::jsonb
WHERE id = 'daily_dua_019';


-- 6. Verify -----------------------------------------------------------------
SELECT id, title, recommended_count,
       CASE WHEN phrases IS NULL THEN 0 ELSE jsonb_array_length(phrases) END AS phrase_count,
       (arabic ~ '[A-Za-z]') AS arabic_has_english
FROM azkar_items
WHERE id IN ('daily_dua_009','daily_dua_014','daily_dua_016','daily_dua_017','daily_dua_019')
ORDER BY id;

COMMIT;
