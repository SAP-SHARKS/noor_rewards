const fs = require('fs');

// Load LWA evening data for items that have evening-specific Arabic text
const eveningLwa = JSON.parse(fs.readFileSync('evening_adhkar_data.json', 'utf-8'));
const lwa = {};
eveningLwa.adhkar.forEach(c => lwa[c.id] = c);

// Audio sources
const _surah = (n) => `https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/${n}.mp3`;
const _ayah  = (s, a) => `https://audio.qurancdn.com/Alafasy/mp3/${String(s).padStart(3,'0')}${String(a).padStart(3,'0')}.mp3`;
const _hm    = (id) => `https://www.hisnmuslim.com/audio/ar/${id}.mp3`;
const _lwa   = (n) => `https://static.lifewithallah.com/file/LifeWithAllah/main/8-Evening/${n}.mp3`;

// ══════════════════════════════════════════════════════════════════════════════
// Evening azkar: 31 items mirroring duaandazkar.com app exactly
// Items 1-11: Quranic (same as morning)
// Items 12-31: Duas (evening wording — "amsaina/amsaitu" instead of "asbahna/asbahtu")
// ══════════════════════════════════════════════════════════════════════════════

const evening = [
  // ── 1. Al-Fatiha ──
  {
    id: 'evening_1', sort_order: 1, recommended_count: 1,
    reward: 'Al Fateha: The Opening of the Quran',
    reference: 'Quran 1:1-7',
    audio_url: _surah(1),
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِيْنَ ، الرَّحْمٰنِ الرَّحِيْمِ ، مَالِكِ يَوْمِ الدِّيْنِ ، إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِيْنُ ، اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيْمَ ، صِرَاطَ الَّذِيْنَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوْبِ عَلَيْهِمْ وَلَا الضَّالِّيْنَ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Al-hamdu lillahi Rabbil-'alamin. Ar-Rahmanir-Rahim. Maliki yawmid-din. Iyyaka na'budu wa iyyaka nasta'in. Ihdinas-siratal-mustaqim. Siratal-ladhina an'amta 'alayhim, ghayril-maghdubi 'alayhim wa lad-dallin.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. All praise is due to Allah, Lord of the worlds. The Most Gracious, the Most Merciful. Master of the Day of Judgment. You alone we worship, and You alone we ask for help. Guide us to the straight path — the path of those upon whom You have bestowed favor, not of those who have evoked Your anger or of those who are astray.`,
    hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Allah said: 'I have divided prayer between Myself and My servant into two halves, and My servant shall have what he has asked for.'"`,
  },
  // ── 2. Al-Baqarah 2:1-5 ──
  {
    id: 'evening_2', sort_order: 2, recommended_count: 1,
    reward: 'Alif Laam Meem: Opening of Al-Baqarah',
    reference: 'Quran 2:1-5, Ad-Darimi',
    audio_url: null,
    arabic: `الٓمٓ ، ذٰلِكَ الْكِتَابُ لَا رَيْبَ فِيْهِ هُدًى لِّلْمُتَّقِيْنَ ، الَّذِيْنَ يُؤْمِنُوْنَ بِالْغَيْبِ وَيُقِيْمُوْنَ الصَّلَاةَ وَمِمَّا رَزَقْنَاهُمْ يُنْفِقُوْنَ ، وَالَّذِيْنَ يُؤْمِنُوْنَ بِمَا أُنْزِلَ إِلَيْكَ وَمَا أُنْزِلَ مِنْ قَبْلِكَ وَبِالْآخِرَةِ هُمْ يُوْقِنُوْنَ ، أُولٰئِكَ عَلَىٰ هُدًى مِنْ رَبِّهِمْ وَأُولٰئِكَ هُمُ الْمُفْلِحُوْنَ`,
    transliteration: `Alif-Lam-Mim. Dhalikal-kitabu la rayba fih, hudal-lil-muttaqin. Alladhina yu'minuna bil-ghaybi wa yuqimunas-salata wa mimma razaqnahum yunfiqun. Walladhina yu'minuna bima unzila ilayka wa ma unzila min qablik, wa bil-akhirati hum yuqinun. Ula'ika 'ala hudam-mir-Rabbihim wa ula'ika humul-muflihun.`,
    translation: `Alif, Lam, Mim. This is the Book about which there is no doubt, a guidance for those conscious of Allah — who believe in the unseen, establish prayer, and spend out of what We have provided for them, and who believe in what has been revealed to you and what was revealed before you, and of the Hereafter they are certain. Those are upon guidance from their Lord, and it is those who are the successful.`,
    hadith_full: `It is reported that the Shaytan will not come near the one who recites the opening verses of Surah Al-Baqarah along with Ayat al-Kursi and the last verses of Al-Baqarah.`,
  },
  // ── 3. Ayat al-Kursi ──
  {
    id: 'evening_3', sort_order: 3, recommended_count: 1,
    reward: 'Ayatul Kursi: The Greatest Protection',
    reference: 'Quran 2:255, Hakim 2064',
    audio_url: _lwa(25),
    arabic: lwa[1].arabic,
    transliteration: lwa[1].transliteration,
    translation: lwa[1].translation,
    hadith_full: lwa[1].reference ? `Reference: ${lwa[1].reference}` : '',
  },
  // ── 4. Al-Baqarah 2:256 ──
  {
    id: 'evening_4', sort_order: 4, recommended_count: 1,
    reward: 'La Ikraha fid-Deen: No Compulsion in Religion',
    reference: 'Quran 2:256',
    audio_url: _ayah(2, 256),
    arabic: `لَا إِكْرَاهَ فِي الدِّيْنِ ، قَدْ تَبَيَّنَ الرُّشْدُ مِنَ الْغَيِّ ، فَمَنْ يَّكْفُرْ بِالطَّاغُوْتِ وَيُؤْمِنْ بِاللّٰهِ فَقَدِ اسْتَمْسَكَ بِالْعُرْوَةِ الْوُثْقَىٰ لَا انْفِصَامَ لَهَا ، وَاللّٰهُ سَمِيْعٌ عَلِيْمٌ`,
    transliteration: `La ikraha fid-din, qad tabayyanar-rushdu minal-ghayy. Faman yakfur bit-taghuti wa yu'min billahi faqadis-tamsaka bil-'urwatil-wuthqa lanfisama laha. Wallahu Sami'un 'Alim.`,
    translation: `There shall be no compulsion in the religion. The right course has become clear from the wrong. So whoever disbelieves in false deities and believes in Allah has grasped the most trustworthy handhold with no break in it. And Allah is Hearing and Knowing.`,
    hadith_full: `This verse establishes the principle that faith must come from sincere conviction.`,
  },
  // ── 5. Al-Baqarah 2:257 ──
  {
    id: 'evening_5', sort_order: 5, recommended_count: 1,
    reward: 'Allah is the Ally of the Believers',
    reference: 'Quran 2:257',
    audio_url: _ayah(2, 257),
    arabic: `اَللّٰهُ وَلِيُّ الَّذِيْنَ آمَنُوْا يُخْرِجُهُمْ مِّنَ الظُّلُمَاتِ إِلَى النُّوْرِ ، وَالَّذِيْنَ كَفَرُوْا أَوْلِيَاؤُهُمُ الطَّاغُوْتُ يُخْرِجُوْنَهُمْ مِّنَ النُّوْرِ إِلَى الظُّلُمَاتِ ، أُولٰئِكَ أَصْحَابُ النَّارِ هُمْ فِيْهَا خَالِدُوْنَ`,
    transliteration: `Allahu waliyyul-ladhina amanu yukhrijuhum minaz-zulumati ilan-nur. Walladhina kafaru awliya'uhumut-taghut, yukhrijunahum minan-nuri ilaz-zulumat. Ula'ika as-habun-nar, hum fiha khalidun.`,
    translation: `Allah is the ally of those who believe. He brings them out from darknesses into the light. And those who disbelieve — their allies are false deities. They take them out of the light into darknesses. Those are the companions of the Fire; they will abide eternally therein.`,
    hadith_full: `This verse affirms that Allah guides and protects the believers.`,
  },
  // ── 6. Al-Baqarah 2:284 ──
  {
    id: 'evening_6', sort_order: 6, recommended_count: 1,
    reward: 'To Allah Belongs All That Is in the Heavens and Earth',
    reference: 'Quran 2:284',
    audio_url: _ayah(2, 284),
    arabic: `لِلّٰهِ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ، وَإِنْ تُبْدُوْا مَا فِيْ أَنْفُسِكُمْ أَوْ تُخْفُوْهُ يُحَاسِبْكُمْ بِهِ اللّٰهُ ، فَيَغْفِرُ لِمَنْ يَّشَاءُ وَيُعَذِّبُ مَنْ يَّشَاءُ ، وَاللّٰهُ عَلَىٰ كُلِّ شَيْءٍ قَدِيْرٌ`,
    transliteration: `Lillahi ma fis-samawati wa ma fil-ard. Wa in tubdu ma fi anfusikum aw tukhfuhu yuhasibkum bihillah. Fayaghfiru limay-yasha'u wa yu'adhdhibu may-yasha'. Wallahu 'ala kulli shay'in qadir.`,
    translation: `To Allah belongs whatever is in the heavens and whatever is in the earth. Whether you show what is within yourselves or conceal it, Allah will bring you to account for it. Then He will forgive whom He wills and punish whom He wills, and Allah is over all things competent.`,
    hadith_full: `The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him."`,
  },
  // ── 7. Al-Baqarah 2:285 ──
  {
    id: 'evening_7', sort_order: 7, recommended_count: 1,
    reward: 'The Messenger Has Believed',
    reference: 'Quran 2:285, Bukhari 5009',
    audio_url: _ayah(2, 285),
    arabic: `آمَنَ الرَّسُوْلُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَّبِّهِ وَالْمُؤْمِنُوْنَ ، كُلٌّ آمَنَ بِاللّٰهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّنْ رُسُلِهِ ، وَقَالُوْا سَمِعْنَا وَأَطَعْنَا غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيْرُ`,
    transliteration: `Amanar-Rasulu bima unzila ilayhi mir-Rabbihi wal-mu'minun. Kullun amana billahi wa mala'ikatihi wa kutubihi wa rusulih, la nufarriqu bayna ahadim-mir-rusulih. Wa qalu sami'na wa ata'na, ghufranaka Rabbana wa ilaykal-masir.`,
    translation: `The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah and His angels and His books and His messengers, saying, "We make no distinction between any of His messengers." And they say, "We hear and we obey. Grant us Your forgiveness, our Lord, and to You is the final destination."`,
    hadith_full: `Abu Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him."`,
  },
  // ── 8. Al-Baqarah 2:286 ──
  {
    id: 'evening_8', sort_order: 8, recommended_count: 1,
    reward: 'Allah Does Not Burden a Soul Beyond Capacity',
    reference: 'Quran 2:286, Bukhari 5009',
    audio_url: _ayah(2, 286),
    arabic: `لَا يُكَلِّفُ اللّٰهُ نَفْسًا إِلَّا وُسْعَهَا ، لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ، رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِيْنَا أَوْ أَخْطَأْنَا ، رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِيْنَ مِنْ قَبْلِنَا ، رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ، وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ، أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِيْنَ`,
    transliteration: `La yukallifullahu nafsan illa wus'aha. Laha ma kasabat wa 'alayha maktasabat. Rabbana la tu'akhidhna in nasina aw akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'alal-ladhina min qablina. Rabbana wa la tuhammilna ma la taqata lana bih. Wa'fu 'anna waghfir lana warhamna. Anta mawlana fansurna 'alal-qawmil-kafirin.`,
    translation: `Allah does not burden a soul beyond that it can bear. It will have the consequence of what good it has gained, and it will bear the consequence of what evil it has earned. "Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people."`,
    hadith_full: `Abu Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him."`,
  },
  // ── 9. Al-Ikhlas ──
  {
    id: 'evening_9', sort_order: 9, recommended_count: 3,
    reward: 'Surah Al-Ikhlas: Sincerity',
    reference: 'Abu Dawud 5082',
    audio_url: _surah(112),
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ هُوَ اللّٰهُ أَحَدٌ ، اَللّٰهُ الصَّمَدُ ، لَمْ يَلِدْ وَلَمْ يُوْلَدْ ، وَلَمْ يَكُنْ لَّهُ كُفُوًا أَحَدٌ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn three times in the morning and evening — they will suffice you against everything."`,
  },
  // ── 10. Al-Falaq ──
  {
    id: 'evening_10', sort_order: 10, recommended_count: 3,
    reward: 'Surah Al-Falaq: Seek Refuge from Evil',
    reference: 'Abu Dawud 5082',
    audio_url: _surah(113),
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ أَعُوْذُ بِرَبِّ الْفَلَقِ ، مِنْ شَرِّ مَا خَلَقَ ، وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ، وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ، وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn three times in the morning and evening — they will suffice you against everything."`,
  },
  // ── 11. An-Nas ──
  {
    id: 'evening_11', sort_order: 11, recommended_count: 3,
    reward: 'Surah An-Nas: Seek Refuge from Whispers',
    reference: 'Abu Dawud 5082',
    audio_url: _surah(114),
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ أَعُوْذُ بِرَبِّ النَّاسِ ، مَلِكِ النَّاسِ ، إِلٰهِ النَّاسِ ، مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ، الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِ ، مِنَ الْجِنَّةِ وَالنَّاسِ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer — who whispers in the breasts of mankind — from among the jinn and mankind."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn three times in the morning and evening — they will suffice you against everything."`,
  },

  // ══════════════════════════════════════════════════════════════════════════
  // Items 12-31: ALL inline — uses LWA evening data (correct "amsaina" text)
  // ══════════════════════════════════════════════════════════════════════════

  // ── 12. Sovereignty (LWA#11) ──
  { id: 'evening_12', sort_order: 12, recommended_count: 1, reward: 'Evening Supplication: Dominion Belongs to Allah', reference: 'Muslim 2723', audio_url: _lwa(35), arabic: lwa[11].arabic, transliteration: lwa[11].transliteration, translation: lwa[11].translation, hadith_full: `Abdullah ibn Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) used to say in the evening: "Amsaina wa amsal-mulku lillah..."` },

  // ── 13. Fitrah (LWA#9) ──
  { id: 'evening_13', sort_order: 13, recommended_count: 1, reward: 'Upon the Fitrah of Islam', reference: 'Ahmad 15367', audio_url: _lwa(33), arabic: lwa[9].arabic, transliteration: lwa[9].transliteration, translation: lwa[9].translation, hadith_full: lwa[9].reference ? `Reference: ${lwa[9].reference}` : '' },

  // ── 14. By Your Leave (LWA#14) ──
  { id: 'evening_14', sort_order: 14, recommended_count: 1, reward: 'By Your Leave We Have Reached the Evening', reference: 'Al-Adab al-Mufrad 1199', audio_url: _lwa(38), arabic: lwa[14].arabic, transliteration: lwa[14].transliteration, translation: lwa[14].translation, hadith_full: lwa[14].reference ? `Reference: ${lwa[14].reference}` : '' },

  // ── 15. Blessings & Concealment (NEW — inline) ──
  { id: 'evening_15', sort_order: 15, recommended_count: 3, reward: 'Blessings, Well-being and Concealment', reference: 'Ibn al-Sunni 41', audio_url: null,
    arabic: `اَللّٰهُمَّ إِنِّيْ أَمْسَيْتُ مِنْكَ فِيْ نِعْمَةٍ وَعَافِيَةٍ وَسِتْرٍ ، فَأَتِمَّ عَلَيَّ نِعْمَتَكَ وَعَافِيَتَكَ وَسِتْرَكَ فِي الدُّنْيَا وَالْآخِرَةِ`,
    transliteration: `Allahumma inni amsaitu minka fi ni'matin wa 'afiyatin wa sitr, fa atimma 'alayya ni'mataka wa 'afiyataka wa sitraka fid-dunya wal-akhirah.`,
    translation: `O Allah, I have entered the evening receiving from You blessings, well-being and concealment of my faults. So complete Your blessings upon me, Your well-being, and Your concealment in this world and the Hereafter.`,
    hadith_full: `The Messenger of Allah (ﷺ) never used to leave this supplication in the morning and evening.` },

  // ── 16. Gratitude (LWA#8) ──
  { id: 'evening_16', sort_order: 16, recommended_count: 1, reward: 'Fulfil Your Obligation to Thank Allah', reference: 'Abu Dawud 5073', audio_url: _lwa(32), arabic: lwa[8].arabic, transliteration: lwa[8].transliteration, translation: lwa[8].translation, hadith_full: `Abdullah ibn Ghannam (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever says this — he has fulfilled his duty of giving thanks for that day."` },

  // ── 17. Ya Rabbi lakal hamdu (NEW — inline) ──
  { id: 'evening_17', sort_order: 17, recommended_count: 1, reward: 'Praise Befitting Divine Greatness', reference: 'Ibn Majah 3801', audio_url: null,
    arabic: `يَا رَبِّ لَكَ الْحَمْدُ كَمَا يَنْبَغِيْ لِجَلَالِ وَجْهِكَ وَعَظِيْمِ سُلْطَانِكَ`,
    transliteration: `Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.`,
    translation: `O my Lord, all praise is due to You as befits the Glory of Your Countenance and the Greatness of Your Authority.`,
    hadith_full: `The Prophet (ﷺ) said, "A servant said this and the angels did not know how to record it. Allah said: 'Record it as My servant said it, until he meets Me and I shall reward him for it.'"` },

  // ── 18. Raditu billahi (LWA#17) ──
  { id: 'evening_18', sort_order: 18, recommended_count: 3, reward: 'Pleased with Allah as Lord', reference: 'Abu Dawud 5072', audio_url: _lwa(41), arabic: lwa[17].arabic, transliteration: lwa[17].transliteration, translation: lwa[17].translation, hadith_full: `The Prophet (ﷺ) said, "Whoever says 'Raditu billahi Rabba, wa bil-Islami dina, wa bi-Muhammadin nabiyya' — it is a right upon Allah to please him on the Day of Judgment."` },

  // ── 19. Well-being (LWA#5) ──
  { id: 'evening_19', sort_order: 19, recommended_count: 1, reward: 'Well-being in this World and the Hereafter', reference: 'Ibn Majah 2/323', audio_url: _lwa(29), arabic: lwa[5].arabic, transliteration: lwa[5].transliteration, translation: lwa[5].translation, hadith_full: lwa[5].reference ? `Reference: ${lwa[5].reference}` : '' },

  // ── 20. SubhanAllah 'adada (LWA#24 from morning — same text) ──
  { id: 'evening_20', sort_order: 20, recommended_count: 3, reward: 'SubhanAllah wa bihamdihi: Outweigh All Other Dhikr', reference: 'Muslim 2726', audio_url: _hm(94),
    arabic: `سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ ، عَدَدَ خَلْقِهِ ، وَرِضَا نَفْسِهِ ، وَزِنَةَ عَرْشِهِ ، وَمِدَادَ كَلِمَاتِهِ`,
    transliteration: `SubhanAllahi wa bihamdihi, 'adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatihi.`,
    translation: `Allah is free from imperfection and all praise is due to Him, as numerous as all He has created, as vast as His pleasure, as limitless as the weight of His Throne, and as endless as the ink of His words.`,
    hadith_full: `Juwairiyah (رضي الله عنها) reported: The Prophet (ﷺ) said, "I said four phrases three times and if they were weighed against all you have said since morning, they would outweigh them."` },

  // ── 21. Bismillah protection (LWA#18) ──
  { id: 'evening_21', sort_order: 21, recommended_count: 3, reward: 'Protect Yourself From All Harm', reference: 'Abu Dawud 5088, Tirmidhi 3388', audio_url: _lwa(42), arabic: lwa[18].arabic, transliteration: lwa[18].transliteration, translation: lwa[18].translation, hadith_full: `Uthman ibn Affan (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "No servant says this three times in the morning and evening, and anything will harm him."` },

  // ── 22. Shirk refuge (NEW — inline) ──
  { id: 'evening_22', sort_order: 22, recommended_count: 3, reward: 'Seek Refuge from Shirk', reference: 'Ahmad 23119', audio_url: 'https://salafiaudio.files.wordpress.com/2015/07/hisn-al-muslim-audio-dua-203.mp3',
    arabic: `اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ أَنْ أُشْرِكَ بِكَ وَأَنَا أَعْلَمُ ، وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ`,
    transliteration: `Allahumma inni a'udhu bika an ushrika bika wa ana a'lam, wa astaghfiruka lima la a'lam.`,
    translation: `O Allah, I seek refuge in You from associating anything with You knowingly, and I seek Your forgiveness for what I do not know.`,
    hadith_full: `Ma'qil ibn Yasar (رضي الله عنه) reported: The Prophet (ﷺ) said this protects from shirk.` },

  // ── 23. Perfect words (LWA#23) ──
  { id: 'evening_23', sort_order: 23, recommended_count: 3, reward: 'Protection From All Evil Wherever You Are', reference: 'Muslim 2708', audio_url: _lwa(47), arabic: lwa[23].arabic, transliteration: lwa[23].transliteration, translation: lwa[23].translation, hadith_full: `Khawlah bint Hakim (رضي الله عنها) reported: "Whoever says this — nothing will harm him until he leaves that place."` },

  // ── 24. Knower of unseen (LWA#6) ──
  { id: 'evening_24', sort_order: 24, recommended_count: 1, reward: 'Knower of the Unseen: Protection from Evil', reference: 'Tirmidhi 3392', audio_url: _lwa(30), arabic: lwa[6].arabic, transliteration: lwa[6].transliteration, translation: lwa[6].translation, hadith_full: lwa[6].reference ? `Reference: ${lwa[6].reference}` : '' },

  // ── 25. Ya Hayyu Ya Qayyum (LWA#7) ──
  { id: 'evening_25', sort_order: 25, recommended_count: 1, reward: 'Ya Hayyu Ya Qayyum: Rectify All My Affairs', reference: 'Hakim 1/545', audio_url: _lwa(31), arabic: lwa[7].arabic, transliteration: lwa[7].transliteration, translation: lwa[7].translation, hadith_full: `Anas ibn Malik (رضي الله عنه) reported: The Prophet (ﷺ) said to Fatimah, "Say in the morning and evening: 'Ya Hayyu ya Qayyumu birahmatika astaghith...'"` },

  // ── 26. Sayyid al-Istighfar (LWA#3) ──
  { id: 'evening_26', sort_order: 26, recommended_count: 1, reward: 'Sayyid al-Istighfar: The Best Forgiveness', reference: 'Bukhari 6306', audio_url: _lwa(27), arabic: lwa[3].arabic, transliteration: lwa[3].transliteration, translation: lwa[3].translation, hadith_full: `Shaddad ibn Aws (رضي الله عنه) reported: The Prophet (ﷺ) said, "The most superior way of asking for forgiveness is Sayyidul-Istighfar. Whoever says it during the evening with firm belief and dies that night, he will be from the people of Paradise."` },

  // ── 27. Freed from Hellfire (LWA#13) ──
  { id: 'evening_27', sort_order: 27, recommended_count: 4, reward: 'Get Yourself Freed from the Hellfire', reference: 'Abu Dawud 5069', audio_url: _lwa(37), arabic: lwa[13].arabic, transliteration: lwa[13].transliteration, translation: lwa[13].translation, hadith_full: `Anas (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says it four times, Allah will free him from the Fire."` },

  // ── 28. Health (LWA#15) ──
  { id: 'evening_28', sort_order: 28, recommended_count: 3, reward: 'Ask Allah For Good Health and Protection', reference: 'Abu Dawud 5090', audio_url: _lwa(39), arabic: lwa[15].arabic, transliteration: lwa[15].transliteration, translation: lwa[15].translation, hadith_full: lwa[15].reference ? `Reference: ${lwa[15].reference}` : '' },

  // ── 29. Hasbiyallahu (LWA#16) ──
  { id: 'evening_29', sort_order: 29, recommended_count: 7, reward: 'Allah Will Suffice You in Everything', reference: 'Abu Dawud 5081', audio_url: _lwa(40), arabic: lwa[16].arabic, transliteration: lwa[16].transliteration, translation: lwa[16].translation, hadith_full: `Abu ad-Darda' (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says this seven times, Allah will suffice him."` },

  // ── 30. La ilaha 100x (LWA#20) ──
  { id: 'evening_30', sort_order: 30, recommended_count: 100, reward: 'An Unparalleled Reward', reference: 'Bukhari 6403, Muslim', audio_url: _lwa(44), arabic: lwa[20].arabic, transliteration: lwa[20].transliteration, translation: lwa[20].translation, hadith_full: `Abu Huraira (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says this one hundred times a day will get the reward of freeing ten slaves, one hundred good deeds, one hundred sins erased, and it will be a shield from Satan."` },

  // ── 31. SubhanAllah 100x (LWA#19) ──
  { id: 'evening_31', sort_order: 31, recommended_count: 100, reward: 'Get Your Sins Forgiven', reference: 'Bukhari 6405, Muslim 2692', audio_url: _lwa(43), arabic: lwa[19].arabic, transliteration: lwa[19].transliteration, translation: lwa[19].translation, hadith_full: `Abu Huraira (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says SubhanAllahi wa bihamdihi one hundred times a day, his sins will be forgiven even if they were as much as the foam of the sea."` },

  // ── 32. Durood Ibrahim (LWA#22) ──
  { id: 'evening_32', sort_order: 32, recommended_count: 10, reward: 'Receive the Intercession of the Prophet ﷺ', reference: 'Bukhari 6357', audio_url: _lwa(46), arabic: lwa[22].arabic, transliteration: lwa[22].transliteration, translation: lwa[22].translation, hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever sends blessings upon me ten times in the morning and ten times in the evening, my intercession will reach him on the Day of Judgment."` },
];

// ══════════════════════════════════════════════════════════════════════════════
// Generate SQL + update azkar.json
// ══════════════════════════════════════════════════════════════════════════════

const esc = (s) => (s || '').replace(/'/g, "''");
let sql = `-- Evening Azkar Migration: duaandazkar.com app exact 31-item sequence
-- Generated: ${new Date().toISOString()}
-- Run this in Supabase SQL Editor

-- Step 1: Delete ALL old evening azkar
DELETE FROM azkar_items WHERE category_id = 'evening';
DELETE FROM azkar_items WHERE id LIKE 'evening_%';
DELETE FROM azkar_items WHERE id LIKE 'evening_fixed_%';
DELETE FROM azkar_items WHERE id LIKE 'evening_lwa_%';

-- Step 2: Insert 31 evening azkar
`;

for (const item of evening) {
  sql += `INSERT INTO azkar_items (id, arabic, transliteration, translation, recommended_count, category_id, reward, reference, sort_order, hadith_full${item.audio_url ? ', audio_url' : ''})
VALUES ('${esc(item.id)}', '${esc(item.arabic)}', '${esc(item.transliteration)}', '${esc(item.translation)}', ${item.recommended_count}, 'evening', '${esc(item.reward)}', '${esc(item.reference)}', ${item.sort_order}, '${esc(item.hadith_full)}'${item.audio_url ? `, '${esc(item.audio_url)}'` : ''});\n\n`;
}

sql += `-- Verify
SELECT id, sort_order, reward, recommended_count, LEFT(arabic, 40) as arabic_start FROM azkar_items WHERE category_id = 'evening' ORDER BY sort_order;\n`;

// Apply hadith overrides — same full texts as morning, mapped to evening IDs
const hadithOverrides = {
  'evening_1':  { reward: 'Al Fateha | Sahih Muslim 395a', reference: 'Quran 1:1-7 | Sahih Muslim 395', hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Allah the Almighty said: 'I have divided prayer between Myself and My servant into two halves, and My servant shall have what he has asked for. When the servant says Al-hamdu lillahi Rabbil-'alamin, Allah says: My servant has praised Me. When he says Ar-Rahmanir-Rahim, Allah says: My servant has extolled Me. When he says Maliki yawmid-din, Allah says: My servant has glorified Me. When he says Iyyaka na'budu wa iyyaka nasta'in, Allah says: This is between Me and My servant, and My servant shall have what he has asked for. When he says Ihdinas-siratal-mustaqim, Allah says: This is for My servant, and My servant shall have what he has asked for.'" (Sahih Muslim 395a)` },
  'evening_2':  { reward: 'Alif Laam Meem | Ad-Darimi', reference: 'Quran 2:1-5 | Ad-Darimi', hadith_full: `Abdullah ibn Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the first four verses of Surah Al-Baqarah, Ayat al-Kursi, and the last three verses of Surah Al-Baqarah — the Shaytan will not come near him or to his family, nor will he be touched by anything that he dislikes." (Ad-Darimi)` },
  'evening_3':  { reward: 'Ayatul Kursi | Al-Bukhari 5010', reference: 'Quran 2:255 | Al-Bukhari 5010', hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) entrusted me to guard the Zakat revenue of Ramadan. Someone came and began stealing from the food. He said, "When you go to your bed, recite Ayat al-Kursi, for then there will be a guard from Allah who will protect you all night long, and Satan will not be able to come near you till dawn." The Prophet (ﷺ) said, "He told you the truth, although he is a liar — that was the Shaytan." (Al-Bukhari 5010)` },
  'evening_4':  { reward: 'La Ikraha fid-Deen | Ad-Darimi', reference: 'Quran 2:256 | Ad-Darimi', hadith_full: `This verse is part of the ten verses from Surah Al-Baqarah that the Prophet (ﷺ) recommended. Whoever recites them, the Shaytan will not enter his house that night. (Ad-Darimi)` },
  'evening_5':  { reward: 'Allah is the Ally of the Believers | Ad-Darimi', reference: 'Quran 2:257 | Ad-Darimi', hadith_full: `This verse is part of the ten verses from Surah Al-Baqarah. Whoever recites them, the Shaytan will not enter his house that night. (Ad-Darimi)` },
  'evening_6':  { reward: 'To Allah Belongs All | Al-Bukhari 4723', reference: 'Quran 2:284 | Al-Bukhari 4723', hadith_full: `Abu Mas'ud al-Badri (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, it will suffice him." (Al-Bukhari 4723)` },
  'evening_7':  { reward: 'The Messenger Has Believed | Al-Bukhari 4723', reference: 'Quran 2:285 | Al-Bukhari 4723', hadith_full: `Abu Mas'ud al-Badri (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, it will suffice him." (Al-Bukhari 4723, Sahih Muslim 807)` },
  'evening_8':  { reward: 'Allah Does Not Burden a Soul | Sahih Muslim 807', reference: 'Quran 2:286 | Sahih Muslim 807', hadith_full: `Abu Mas'ud al-Badri (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, it will suffice him." When this verse was revealed, after each supplication in it, Allah said: "I have done so." (Sahih Muslim 807)` },
  'evening_9':  { reward: 'Surah Al-Ikhlas | Abu Dawud 5082', reference: 'Quran 112 | Abu Dawud 5082', hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn three times at dawn and dusk. It will suffice you in all respects." (Abu Dawud 5082, At-Tirmidhi 3575)` },
  'evening_10': { reward: 'Surah Al-Falaq | At-Tirmidhi 3575', reference: 'Quran 113 | At-Tirmidhi 3575', hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn three times at dawn and dusk. It will suffice you in all respects." (Abu Dawud 5082, At-Tirmidhi 3575)` },
  'evening_11': { reward: 'Surah An-Nas | At-Tirmidhi 3575', reference: 'Quran 114 | At-Tirmidhi 3575', hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn three times at dawn and dusk. It will suffice you in all respects." (Abu Dawud 5082, At-Tirmidhi 3575)` },
  'evening_12': { reward: 'Dominion Belongs to Allah | Sahih Muslim 2723', reference: 'Sahih Muslim 2723' },
  'evening_13': { reward: 'Upon the Fitrah of Islam | Ahmad 15367', reference: 'Ahmad 15367' },
  'evening_14': { reward: 'By Your Leave | At-Tirmidhi 3391', reference: 'At-Tirmidhi 3391' },
  'evening_16': { reward: 'Fulfil Obligation of Gratitude | Abu Dawud 5073', reference: 'Abu Dawud 5073', hadith_full: `Abdullah ibn Ghannam (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever says: 'Allahumma ma amsa bi min ni'matin...' — he has fulfilled his obligation of giving thanks for that night." (Abu Dawud 5073)` },
  'evening_18': { reward: 'Pleased with Allah | Ahmad 18967', reference: 'Abu Dawud 5072 | Ahmad 18967', hadith_full: `Abu Sallam (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says in the morning and evening: 'Raditu billahi Rabba, wa bil-Islami dina, wa bi-Muhammadin nabiyya' — Allah has promised that He will please him on the Day of Resurrection." (Abu Dawud 5072, Ahmad 18967)` },
  'evening_19': { reward: 'Well-being in Both Worlds | Abu Dawud 5074', reference: 'Abu Dawud 5074', hadith_full: `Abdullah ibn Umar (رضي الله عنهما) reported: The Messenger of Allah (ﷺ) never failed to say these supplications in the morning and evening. (Abu Dawud 5074)` },
  'evening_20': { reward: 'Outweigh All Other Dhikr | Sahih Muslim 2726', reference: 'Sahih Muslim 2726' },
  'evening_21': { reward: 'Protect From All Harm | At-Tirmidhi 3388', reference: 'Abu Dawud 5088 | At-Tirmidhi 3388', hadith_full: `Uthman ibn Affan (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "No servant says this three times in the morning and evening, and anything will harm him." (At-Tirmidhi 3388)` },
  'evening_22': { reward: 'Seek Refuge from Shirk | Sahih Al-Jaami 2876', reference: 'Ahmad 23119 | Sahih Al-Jaami 2876', hadith_full: `Ma'qil ibn Yasar (رضي الله عنه) reported: The Prophet (ﷺ) said, "Shirk among you is more subtle than the sound of footsteps of an ant on a rock. Shall I not teach you something which, if you say it, will rid you of both minor and major shirk? Say: 'Allahumma inni a'udhu bika an ushrika bika wa ana a'lam, wa astaghfiruka lima la a'lam.'" (Sahih Al-Jaami 2876)` },
  'evening_23': { reward: 'Protection From All Evil | Sahih Muslim 2709', reference: 'Sahih Muslim 2709', hadith_full: `Khawlah bint Hakim (رضي الله عنها) reported: The Messenger of Allah (ﷺ) said, "If anyone lands at a place and says: 'A'udhu bi kalimatillahit-tammati min sharri ma khalaq' — nothing will harm him until he leaves that place." (Sahih Muslim 2709)` },
  'evening_24': { reward: 'Knower of the Unseen | At-Tirmidhi 3392', reference: 'At-Tirmidhi 3392' },
  'evening_25': { reward: 'Ya Hayyu Ya Qayyum | Mustadrak Al-Hakim', reference: 'Hakim 1/545' },
  'evening_26': { reward: 'Sayyid al-Istighfar | Al-Bukhari 6306', reference: 'Al-Bukhari 6306', hadith_full: `Shaddad ibn Aws (رضي الله عنه) reported: The Prophet (ﷺ) said, "The most superior way of asking for forgiveness is Sayyidul-Istighfar. Whoever says it at night with firm belief in it, and dies before morning comes, he will be one of the people of Paradise." (Al-Bukhari 6306)` },
  'evening_27': { reward: 'Freed from the Hellfire | Abu Dawud 5069', reference: 'Abu Dawud 5069', hadith_full: `The Prophet (ﷺ) said, "Whoever says this four times in the evening, Allah will free him from the Fire." (Abu Dawud 5069)` },
  'evening_28': { reward: 'Good Health & Protection | Abu Dawud 5090', reference: 'Abu Dawud 5090' },
  'evening_29': { reward: 'Allah Will Suffice You | Abu Dawud 5081', reference: 'Abu Dawud 5081', hadith_full: `Abu ad-Darda' (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says this seven times in the morning and evening, Allah will suffice him against whatever concerns him." (Abu Dawud 5081)` },
  'evening_30': { reward: 'An Unparalleled Reward | Al-Bukhari 6403', reference: 'Al-Bukhari 6403 | Sahih Muslim 2693', hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever says this one hundred times a day will get the same reward as given for manumitting ten slaves; one hundred good deeds will be written, one hundred sins deducted, and it will be a shield from Satan." (Al-Bukhari 6403)` },
  'evening_31': { reward: 'Get Your Sins Forgiven | Al-Bukhari 6405', reference: 'Al-Bukhari 6405 | Sahih Muslim 2691', hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever says 'SubhanAllahi wa bihamdihi' one hundred times a day, his sins will be forgiven even if they were as much as the foam of the sea." (Al-Bukhari 6405)` },
  'evening_32': { reward: 'Durood Ibrahim | Al-Bukhari 6357', reference: 'Al-Bukhari 6357', hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Whoever sends blessings upon me ten times in the morning and ten times in the evening, my intercession will reach him on the Day of Judgment." (At-Tabarani, Sahih Al-Jaami 6357)` },
};

// Apply hadith overrides before generating SQL
for (const item of evening) {
  const ov = hadithOverrides[item.id];
  if (ov) {
    if (ov.reward) item.reward = ov.reward;
    if (ov.reference) item.reference = ov.reference;
    if (ov.hadith_full) item.hadith_full = ov.hadith_full;
  }
}

// Regenerate SQL with overridden data
let sql2 = `-- Evening Azkar Migration: duaandazkar.com app exact 32-item sequence\n-- Generated: ${new Date().toISOString()}\n-- Run this in Supabase SQL Editor\n\n-- Step 1: Delete ALL old evening azkar\nDELETE FROM azkar_items WHERE category_id = 'evening';\nDELETE FROM azkar_items WHERE id LIKE 'evening_%';\nDELETE FROM azkar_items WHERE id LIKE 'evening_fixed_%';\nDELETE FROM azkar_items WHERE id LIKE 'evening_lwa_%';\n\n-- Step 2: Insert 32 evening azkar\n`;
for (const item of evening) {
  sql2 += `INSERT INTO azkar_items (id, arabic, transliteration, translation, recommended_count, category_id, reward, reference, sort_order, hadith_full${item.audio_url ? ', audio_url' : ''})\nVALUES ('${esc(item.id)}', '${esc(item.arabic)}', '${esc(item.transliteration)}', '${esc(item.translation)}', ${item.recommended_count}, 'evening', '${esc(item.reward)}', '${esc(item.reference)}', ${item.sort_order}, '${esc(item.hadith_full)}'${item.audio_url ? `, '${esc(item.audio_url)}'` : ''});\n\n`;
}
sql2 += `-- Verify\nSELECT id, sort_order, reward, recommended_count, LEFT(arabic, 40) as arabic_start FROM azkar_items WHERE category_id = 'evening' ORDER BY sort_order;\n`;
fs.writeFileSync('_evening_migration.sql', sql2, 'utf-8');

// Update local JSON
const currentAll = JSON.parse(fs.readFileSync('assets/data/azkar.json', 'utf-8'));
const nonEvening = currentAll.filter(i => (i.category_id || i.category || '') !== 'evening');
const localItems = evening.map(i => ({
  id: i.id, arabic: i.arabic, transliteration: i.transliteration, translation: i.translation,
  recommended_count: i.recommended_count, category: 'evening', reward: i.reward,
  reference: i.reference, sort_order: i.sort_order, hadith_full: i.hadith_full, audio_url: i.audio_url,
}));
fs.writeFileSync('assets/data/azkar.json', JSON.stringify([...nonEvening, ...localItems], null, 2), 'utf-8');

console.log('Generated _evening_migration.sql with', evening.length, 'items');
console.log('Updated local azkar.json\n');
evening.forEach((f, i) => {
  const ok = f.arabic && f.arabic.length > 10 ? '✓' : '⚠ MISSING';
  console.log(`${i+1}. [x${f.recommended_count}] ${f.reward} ${ok}`);
});
