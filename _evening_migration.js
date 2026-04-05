const fs = require('fs');

// Load current evening azkar to reuse arabic/transliteration/translation
const eveningLwa = JSON.parse(fs.readFileSync('evening_adhkar_data.json', 'utf-8'));
const lwaById = {};
eveningLwa.adhkar.forEach(c => lwaById[c.id] = c);

// Also load the current evening_fixed items from azkar.json
const allAzkar = JSON.parse(fs.readFileSync('assets/data/azkar.json', 'utf-8'));
const fixedById = {};
allAzkar.filter(i => (i.category_id || i.category) === 'evening').forEach(c => fixedById[c.id] = c);

// Exact 31-item sequence from Dua & Adhkar website (chapter-2-evening-azkar)
const evening = [
  // ── Quranic Passages (1-11) ──
  {
    id: 'evening_1', sort_order: 1, recommended_count: 1,
    reward: 'Al Fateha: The Opening of the Quran',
    reference: 'Quran 1:1-7',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِيْنَ ، الرَّحْمٰنِ الرَّحِيْمِ ، مَالِكِ يَوْمِ الدِّيْنِ ، إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِيْنُ ، اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيْمَ ، صِرَاطَ الَّذِيْنَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوْبِ عَلَيْهِمْ وَلَا الضَّالِّيْنَ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Al-hamdu lillahi Rabbil-'alamin. Ar-Rahmanir-Rahim. Maliki yawmid-din. Iyyaka na'budu wa iyyaka nasta'in. Ihdinas-siratal-mustaqim. Siratal-ladhina an'amta 'alayhim, ghayril-maghdubi 'alayhim wa lad-dallin.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. All praise is due to Allah, Lord of the worlds. The Most Gracious, the Most Merciful. Master of the Day of Judgment. You alone we worship, and You alone we ask for help. Guide us to the straight path — the path of those upon whom You have bestowed favor, not of those who have evoked Your anger or of those who are astray.`,
    hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Allah said: 'I have divided prayer between Myself and My servant into two halves, and My servant shall have what he has asked for.'"`,
  },
  {
    id: 'evening_2', sort_order: 2, recommended_count: 1,
    reward: 'Alif Laam Meem: Opening of Al-Baqarah',
    reference: 'Quran 2:1-5, Ad-Darimi',
    arabic: `الٓمٓ ، ذٰلِكَ الْكِتَابُ لَا رَيْبَ فِيْهِ هُدًى لِّلْمُتَّقِيْنَ ، الَّذِيْنَ يُؤْمِنُوْنَ بِالْغَيْبِ وَيُقِيْمُوْنَ الصَّلَاةَ وَمِمَّا رَزَقْنَاهُمْ يُنْفِقُوْنَ ، وَالَّذِيْنَ يُؤْمِنُوْنَ بِمَا أُنْزِلَ إِلَيْكَ وَمَا أُنْزِلَ مِنْ قَبْلِكَ وَبِالْآخِرَةِ هُمْ يُوْقِنُوْنَ ، أُولٰئِكَ عَلَىٰ هُدًى مِنْ رَبِّهِمْ وَأُولٰئِكَ هُمُ الْمُفْلِحُوْنَ`,
    transliteration: `Alif-Lam-Mim. Dhalikal-kitabu la rayba fih, hudal-lil-muttaqin. Alladhina yu'minuna bil-ghaybi wa yuqimunas-salata wa mimma razaqnahum yunfiqun. Walladhina yu'minuna bima unzila ilayka wa ma unzila min qablik, wa bil-akhirati hum yuqinun. Ula'ika 'ala hudam-mir-Rabbihim wa ula'ika humul-muflihun.`,
    translation: `Alif, Lam, Mim. This is the Book about which there is no doubt, a guidance for those conscious of Allah — who believe in the unseen, establish prayer, and spend out of what We have provided for them, and who believe in what has been revealed to you and what was revealed before you, and of the Hereafter they are certain. Those are upon guidance from their Lord, and it is those who are the successful.`,
    hadith_full: `It is reported that the Shaytan will not come near the one who recites the opening verses of Surah Al-Baqarah along with Ayat al-Kursi and the last verses of Al-Baqarah in the evening.`,
  },
  {
    id: 'evening_3', sort_order: 3, recommended_count: 1,
    reward: 'Ayatul Kursi: The Greatest Protection',
    reference: 'Quran 2:255, Hakim 2064',
    reuse_fixed: 'evening_fixed_1',
  },
  {
    id: 'evening_4', sort_order: 4, recommended_count: 1,
    reward: 'La Ikraha fid-Deen: No Compulsion in Religion',
    reference: 'Quran 2:256',
    arabic: `لَا إِكْرَاهَ فِي الدِّيْنِ ، قَدْ تَبَيَّنَ الرُّشْدُ مِنَ الْغَيِّ ، فَمَنْ يَّكْفُرْ بِالطَّاغُوْتِ وَيُؤْمِنْ بِاللّٰهِ فَقَدِ اسْتَمْسَكَ بِالْعُرْوَةِ الْوُثْقَىٰ لَا انْفِصَامَ لَهَا ، وَاللّٰهُ سَمِيْعٌ عَلِيْمٌ`,
    transliteration: `La ikraha fid-din, qad tabayyanar-rushdu minal-ghayy. Faman yakfur bit-taghuti wa yu'min billahi faqadis-tamsaka bil-'urwatil-wuthqa lanfisama laha. Wallahu Sami'un 'Alim.`,
    translation: `There shall be no compulsion in the religion. The right course has become clear from the wrong. So whoever disbelieves in false deities and believes in Allah has grasped the most trustworthy handhold with no break in it. And Allah is Hearing and Knowing.`,
    hadith_full: `This verse establishes the principle that faith must come from sincere conviction. Reciting it in the evening affirms one's conscious choice of Islam and trust in Allah's guidance.`,
  },
  {
    id: 'evening_5', sort_order: 5, recommended_count: 1,
    reward: 'Allah is the Ally of the Believers',
    reference: 'Quran 2:257',
    arabic: `اَللّٰهُ وَلِيُّ الَّذِيْنَ آمَنُوْا يُخْرِجُهُمْ مِّنَ الظُّلُمَاتِ إِلَى النُّوْرِ ، وَالَّذِيْنَ كَفَرُوْا أَوْلِيَاؤُهُمُ الطَّاغُوْتُ يُخْرِجُوْنَهُمْ مِّنَ النُّوْرِ إِلَى الظُّلُمَاتِ ، أُولٰئِكَ أَصْحَابُ النَّارِ هُمْ فِيْهَا خَالِدُوْنَ`,
    transliteration: `Allahu waliyyul-ladhina amanu yukhrijuhum minaz-zulumati ilan-nur. Walladhina kafaru awliya'uhumut-taghut, yukhrijunahum minan-nuri ilaz-zulumat. Ula'ika as-habun-nar, hum fiha khalidun.`,
    translation: `Allah is the ally of those who believe. He brings them out from darknesses into the light. And those who disbelieve — their allies are false deities. They take them out of the light into darknesses. Those are the companions of the Fire; they will abide eternally therein.`,
    hadith_full: `This verse affirms that Allah guides and protects the believers, bringing them from the darkness of ignorance into the light of faith.`,
  },
  {
    id: 'evening_6', sort_order: 6, recommended_count: 1,
    reward: 'To Allah Belongs All That Is in the Heavens and Earth',
    reference: 'Quran 2:284',
    arabic: `لِلّٰهِ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ، وَإِنْ تُبْدُوْا مَا فِيْ أَنْفُسِكُمْ أَوْ تُخْفُوْهُ يُحَاسِبْكُمْ بِهِ اللّٰهُ ، فَيَغْفِرُ لِمَنْ يَّشَاءُ وَيُعَذِّبُ مَنْ يَّشَاءُ ، وَاللّٰهُ عَلَىٰ كُلِّ شَيْءٍ قَدِيْرٌ`,
    transliteration: `Lillahi ma fis-samawati wa ma fil-ard. Wa in tubdu ma fi anfusikum aw tukhfuhu yuhasibkum bihillah. Fayaghfiru limay-yasha'u wa yu'adhdhibu may-yasha'. Wallahu 'ala kulli shay'in qadir.`,
    translation: `To Allah belongs whatever is in the heavens and whatever is in the earth. Whether you show what is within yourselves or conceal it, Allah will bring you to account for it. Then He will forgive whom He wills and punish whom He wills, and Allah is over all things competent.`,
    hadith_full: `The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him."`,
  },
  {
    id: 'evening_7', sort_order: 7, recommended_count: 1,
    reward: 'The Messenger Has Believed',
    reference: 'Quran 2:285, Bukhari 5009',
    arabic: `آمَنَ الرَّسُوْلُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَّبِّهِ وَالْمُؤْمِنُوْنَ ، كُلٌّ آمَنَ بِاللّٰهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّنْ رُسُلِهِ ، وَقَالُوْا سَمِعْنَا وَأَطَعْنَا غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيْرُ`,
    transliteration: `Amanar-Rasulu bima unzila ilayhi mir-Rabbihi wal-mu'minun. Kullun amana billahi wa mala'ikatihi wa kutubihi wa rusulih, la nufarriqu bayna ahadim-mir-rusulih. Wa qalu sami'na wa ata'na, ghufranaka Rabbana wa ilaykal-masir.`,
    translation: `The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah and His angels and His books and His messengers, saying, "We make no distinction between any of His messengers." And they say, "We hear and we obey. Grant us Your forgiveness, our Lord, and to You is the final destination."`,
    hadith_full: `Abu Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him."`,
  },
  {
    id: 'evening_8', sort_order: 8, recommended_count: 1,
    reward: 'Allah Does Not Burden a Soul Beyond Capacity',
    reference: 'Quran 2:286, Bukhari 5009',
    arabic: `لَا يُكَلِّفُ اللّٰهُ نَفْسًا إِلَّا وُسْعَهَا ، لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ، رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِيْنَا أَوْ أَخْطَأْنَا ، رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِيْنَ مِنْ قَبْلِنَا ، رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ، وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ، أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِيْنَ`,
    transliteration: `La yukallifullahu nafsan illa wus'aha. Laha ma kasabat wa 'alayha maktasabat. Rabbana la tu'akhidhna in nasina aw akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'alal-ladhina min qablina. Rabbana wa la tuhammilna ma la taqata lana bih. Wa'fu 'anna waghfir lana warhamna. Anta mawlana fansurna 'alal-qawmil-kafirin.`,
    translation: `Allah does not burden a soul beyond that it can bear. It will have the consequence of what good it has gained, and it will bear the consequence of what evil it has earned. "Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people."`,
    hadith_full: `Abu Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him." Muslim reported that when this verse was revealed, Allah said after each supplication in it: "I have done so."`,
  },
  {
    id: 'evening_9', sort_order: 9, recommended_count: 3,
    reward: 'Surah Al-Ikhlas: Sincerity',
    reference: 'Abu Dawud 5082, An-Nasa\'i',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ هُوَ اللّٰهُ أَحَدٌ ، اَللّٰهُ الصَّمَدُ ، لَمْ يَلِدْ وَلَمْ يُوْلَدْ ، وَلَمْ يَكُنْ لَّهُ كُفُوًا أَحَدٌ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to me, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn (Al-Falaq and An-Nas) three times in the morning and evening — they will suffice you against everything."`,
  },
  {
    id: 'evening_10', sort_order: 10, recommended_count: 3,
    reward: 'Surah Al-Falaq: Seek Refuge from Evil',
    reference: 'Abu Dawud 5082',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ أَعُوْذُ بِرَبِّ الْفَلَقِ ، مِنْ شَرِّ مَا خَلَقَ ، وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ، وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ، وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to me, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn (Al-Falaq and An-Nas) three times in the morning and evening — they will suffice you against everything."`,
  },
  {
    id: 'evening_11', sort_order: 11, recommended_count: 3,
    reward: 'Surah An-Nas: Seek Refuge from Whispers',
    reference: 'Abu Dawud 5082',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ أَعُوْذُ بِرَبِّ النَّاسِ ، مَلِكِ النَّاسِ ، إِلٰهِ النَّاسِ ، مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ، الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِ ، مِنَ الْجِنَّةِ وَالنَّاسِ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer — who whispers in the breasts of mankind — from among the jinn and mankind."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to me, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn (Al-Falaq and An-Nas) three times in the morning and evening — they will suffice you against everything."`,
  },

  // ── Dua Azkar (12-31) ──
  {
    id: 'evening_12', sort_order: 12, recommended_count: 1,
    reward: 'Evening Supplication: Dominion Belongs to Allah',
    reference: 'Muslim 2723',
    reuse_fixed: 'evening_fixed_11',
  },
  {
    id: 'evening_13', sort_order: 13, recommended_count: 1,
    reward: 'Upon the Fitrah of Islam',
    reference: 'Ahmad 15367',
    reuse_fixed: 'evening_fixed_9',
  },
  {
    id: 'evening_14', sort_order: 14, recommended_count: 1,
    reward: 'By Your Leave We Have Reached the Evening',
    reference: 'Al-Adab al-Mufrad 1199',
    reuse_fixed: 'evening_fixed_14',
  },
  {
    id: 'evening_15', sort_order: 15, recommended_count: 3,
    reward: 'Blessings, Well-being and Concealment',
    reference: 'Ibn al-Sunni 41',
    arabic: `اَللّٰهُمَّ إِنِّيْ أَمْسَيْتُ مِنْكَ فِيْ نِعْمَةٍ وَعَافِيَةٍ وَسِتْرٍ ، فَأَتِمَّ عَلَيَّ نِعْمَتَكَ وَعَافِيَتَكَ وَسِتْرَكَ فِي الدُّنْيَا وَالْآخِرَةِ`,
    transliteration: `Allahumma inni amsaitu minka fi ni'matin wa 'afiyatin wa sitr, fa atimma 'alayya ni'mataka wa 'afiyataka wa sitraka fid-dunya wal-akhirah.`,
    translation: `O Allah, I have entered the evening receiving from You blessings, well-being and concealment (of my faults). So complete Your blessings upon me, Your well-being, and Your concealment in this world and the Hereafter.`,
    hadith_full: `Abdullah ibn Umar (رضي الله عنه) reported: The Messenger of Allah (ﷺ) never used to leave this supplication in the morning and evening, asking Allah to complete His blessings, well-being, and concealment of faults upon him in this world and the Hereafter.`,
  },
  {
    id: 'evening_16', sort_order: 16, recommended_count: 1,
    reward: 'Fulfil Your Obligation to Thank Allah',
    reference: 'Abu Dawud 5073',
    reuse_fixed: 'evening_fixed_8',
  },
  {
    id: 'evening_17', sort_order: 17, recommended_count: 1,
    reward: 'Praise Befitting Divine Greatness',
    reference: 'Ibn Majah 3801',
    arabic: `يَا رَبِّ لَكَ الْحَمْدُ كَمَا يَنْبَغِيْ لِجَلَالِ وَجْهِكَ وَعَظِيْمِ سُلْطَانِكَ`,
    transliteration: `Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.`,
    translation: `O my Lord, all praise is due to You as befits the Glory of Your Countenance and the Greatness of Your Authority.`,
    hadith_full: `Abdullah ibn Umar (رضي الله عنه) reported: The Prophet (ﷺ) said, "A servant said: 'Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.' The two angels did not know how to record it, so they ascended to the heavens and said: 'Our Lord, Your servant has said something and we do not know how to record it.' Allah — while knowing best what His servant said — asked: 'What did My servant say?' They replied: 'He said: Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.' Allah said to them: 'Record it as My servant said it, until he meets Me and I shall reward him for it.'"`,
  },
  {
    id: 'evening_18', sort_order: 18, recommended_count: 3,
    reward: 'Pleased with Allah as Lord',
    reference: 'Abu Dawud 5072, Ahmad 18967',
    reuse_fixed: 'evening_fixed_17',
  },
  {
    id: 'evening_19', sort_order: 19, recommended_count: 1,
    reward: 'Well-being in this World and the Hereafter',
    reference: 'Ibn Majah 2/323',
    reuse_fixed: 'evening_fixed_5',
  },
  {
    id: 'evening_20', sort_order: 20, recommended_count: 3,
    reward: 'SubhanAllah wa bihamdihi: Outweigh All Other Dhikr',
    reference: 'Muslim 2726',
    arabic: `سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ ، عَدَدَ خَلْقِهِ ، وَرِضَا نَفْسِهِ ، وَزِنَةَ عَرْشِهِ ، وَمِدَادَ كَلِمَاتِهِ`,
    transliteration: `SubhanAllahi wa bihamdihi, 'adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatihi.`,
    translation: `Allah is free from imperfection and all praise is due to Him, as numerous as all He has created, as vast as His pleasure, as limitless as the weight of His Throne, and as endless as the ink of His words.`,
    hadith_full: `Juwairiyah (رضي الله عنها) reported: The Prophet (ﷺ) left her in the morning and came back at forenoon. She was still sitting in prayer. He said, "I said four phrases three times after leaving you, and if they were weighed against all you have said since morning, they would outweigh them: SubhanAllahi wa bihamdihi, 'adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatih."`,
  },
  {
    id: 'evening_21', sort_order: 21, recommended_count: 3,
    reward: 'Protect Yourself From All Harm',
    reference: 'Abu Dawud 5088, Tirmidhi 3388',
    reuse_fixed: 'evening_fixed_18',
  },
  {
    id: 'evening_22', sort_order: 22, recommended_count: 3,
    reward: 'Seek Refuge from Shirk',
    reference: 'Ahmad 23119',
    arabic: `اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ أَنْ أُشْرِكَ بِكَ وَأَنَا أَعْلَمُ ، وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ`,
    transliteration: `Allahumma inni a'udhu bika an ushrika bika wa ana a'lam, wa astaghfiruka lima la a'lam.`,
    translation: `O Allah, I seek refuge in You from associating anything with You knowingly, and I seek Your forgiveness for what I do not know.`,
    hadith_full: `Ma'qil ibn Yasar (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says 'Allahumma inni a'udhu bika an ushrika bika wa ana a'lam, wa astaghfiruka lima la a'lam' three times, Allah will protect him from shirk."`,
  },
  {
    id: 'evening_23', sort_order: 23, recommended_count: 3,
    reward: 'Protection From All Evil Wherever You Are',
    reference: 'Muslim 2708, Ahmad',
    reuse_fixed: 'evening_fixed_23',
  },
  {
    id: 'evening_24', sort_order: 24, recommended_count: 1,
    reward: 'Knower of the Unseen: Protection from Evil',
    reference: 'Tirmidhi 3392',
    reuse_fixed: 'evening_fixed_6',
  },
  {
    id: 'evening_25', sort_order: 25, recommended_count: 1,
    reward: 'Ya Hayyu Ya Qayyum: Rectify All My Affairs',
    reference: 'Hakim 1/545',
    reuse_fixed: 'evening_fixed_7',
  },
  {
    id: 'evening_26', sort_order: 26, recommended_count: 1,
    reward: 'Sayyid al-Istighfar: The Best Forgiveness',
    reference: 'Bukhari 6306',
    reuse_fixed: 'evening_fixed_3',
  },
  {
    id: 'evening_27', sort_order: 27, recommended_count: 4,
    reward: 'Get Yourself Freed from the Hellfire',
    reference: 'Abu Dawud 5069',
    reuse_fixed: 'evening_fixed_13',
  },
  {
    id: 'evening_28', sort_order: 28, recommended_count: 3,
    reward: 'Ask Allah For Good Health and Protection',
    reference: 'Abu Dawud 5090',
    reuse_fixed: 'evening_fixed_15',
  },
  {
    id: 'evening_29', sort_order: 29, recommended_count: 7,
    reward: 'Allah Will Suffice You in Everything',
    reference: 'Abu Dawud 5081',
    reuse_fixed: 'evening_fixed_16',
  },
  {
    id: 'evening_30', sort_order: 30, recommended_count: 100,
    reward: 'An Unparalleled Reward',
    reference: 'Bukhari 6403, Muslim',
    reuse_fixed: 'evening_fixed_20',
  },
  {
    id: 'evening_31', sort_order: 31, recommended_count: 100,
    reward: 'Get Your Sins Forgiven',
    reference: 'Bukhari 6405, Muslim 2692',
    reuse_fixed: 'evening_fixed_19',
  },
];

// Build final items
function buildItem(item) {
  if (item.reuse_fixed && fixedById[item.reuse_fixed]) {
    const src = fixedById[item.reuse_fixed];
    return {
      id: item.id,
      arabic: item.arabic || src.arabic,
      transliteration: item.transliteration || src.transliteration,
      translation: item.translation || src.translation,
      recommended_count: item.recommended_count,
      category_id: 'evening',
      reward: item.reward,
      reference: item.reference,
      sort_order: item.sort_order,
      hadith_full: item.hadith_full || src.hadith_full || '',
      audio_url: src.audio_url || null,
    };
  }
  return {
    id: item.id,
    arabic: item.arabic || '',
    transliteration: item.transliteration || '',
    translation: item.translation || '',
    recommended_count: item.recommended_count,
    category_id: 'evening',
    reward: item.reward,
    reference: item.reference,
    sort_order: item.sort_order,
    hadith_full: item.hadith_full || '',
    audio_url: null,
  };
}

const finalItems = evening.map(item => buildItem(item));

// Generate SQL
const esc = (s) => (s || '').replace(/'/g, "''");
let sql = `-- Evening Azkar Migration: Match duaandazkar.com exact 31-item sequence
-- Run this in Supabase SQL Editor

-- Step 1: Delete old evening azkar
DELETE FROM azkar_items WHERE category_id = 'evening';

-- Step 2: Insert new 31 evening azkar
`;

for (const item of finalItems) {
  sql += `INSERT INTO azkar_items (id, arabic, transliteration, translation, recommended_count, category_id, reward, reference, sort_order, hadith_full${item.audio_url ? ', audio_url' : ''})
VALUES ('${esc(item.id)}', '${esc(item.arabic)}', '${esc(item.transliteration)}', '${esc(item.translation)}', ${item.recommended_count}, 'evening', '${esc(item.reward)}', '${esc(item.reference)}', ${item.sort_order}, '${esc(item.hadith_full)}'${item.audio_url ? `, '${esc(item.audio_url)}'` : ''});\n\n`;
}

sql += `-- Verify
SELECT id, sort_order, reward, recommended_count FROM azkar_items WHERE category_id = 'evening' ORDER BY sort_order;\n`;

fs.writeFileSync('_evening_migration.sql', sql, 'utf-8');

// Update local JSON too
const currentAll = JSON.parse(fs.readFileSync('assets/data/azkar.json', 'utf-8'));
const nonEvening = currentAll.filter(i => (i.category_id || i.category || '') !== 'evening');
const localItems = finalItems.map(i => ({
  id: i.id, arabic: i.arabic, transliteration: i.transliteration, translation: i.translation,
  recommended_count: i.recommended_count, category: 'evening', reward: i.reward,
  reference: i.reference, sort_order: i.sort_order, hadith_full: i.hadith_full, audio_url: i.audio_url,
}));
fs.writeFileSync('assets/data/azkar.json', JSON.stringify([...nonEvening, ...localItems], null, 2), 'utf-8');

console.log('Generated _evening_migration.sql with', finalItems.length, 'items');
console.log('Updated local azkar.json\n');
finalItems.forEach((f, i) => {
  const ok = f.arabic.length > 10 ? '✓' : '⚠ MISSING';
  console.log(`${i+1}. [x${f.recommended_count}] ${f.reward} ${ok}`);
});
