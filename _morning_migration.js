const fs = require('fs');

// Load current morning azkar to reuse arabic/transliteration/translation
const current = JSON.parse(fs.readFileSync('_current_morning.json', 'utf-8'));
const byId = {};
current.forEach(c => byId[c.id] = c);

// Exact 32-item sequence from Dua & Adhkar app v7.5.0
const morning = [
  // ── Quranic Passages (1-11) ──
  {
    id: 'morning_1', sort_order: 1, recommended_count: 1,
    reward: 'Al Fateha: The Opening of the Quran',
    reference: 'Quran 1:1-7',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِيْنَ ، الرَّحْمٰنِ الرَّحِيْمِ ، مَالِكِ يَوْمِ الدِّيْنِ ، إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِيْنُ ، اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيْمَ ، صِرَاطَ الَّذِيْنَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوْبِ عَلَيْهِمْ وَلَا الضَّالِّيْنَ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Al-hamdu lillahi Rabbil-'alamin. Ar-Rahmanir-Rahim. Maliki yawmid-din. Iyyaka na'budu wa iyyaka nasta'in. Ihdinas-siratal-mustaqim. Siratal-ladhina an'amta 'alayhim, ghayril-maghdubi 'alayhim wa lad-dallin.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. All praise is due to Allah, Lord of the worlds. The Most Gracious, the Most Merciful. Master of the Day of Judgment. You alone we worship, and You alone we ask for help. Guide us to the straight path — the path of those upon whom You have bestowed favor, not of those who have evoked Your anger or of those who are astray.`,
    hadith_full: `Abu Huraira (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said, "Allah said: 'I have divided prayer between Myself and My servant into two halves, and My servant shall have what he has asked for.' When the servant says 'Al-hamdu lillahi Rabbil-'alamin,' Allah says: 'My servant has praised Me.'"`,
  },
  {
    id: 'morning_2', sort_order: 2, recommended_count: 1,
    reward: 'Alif Laam Meem: Opening of Al-Baqarah',
    reference: 'Quran 2:1-5, Ad-Darimi',
    arabic: `الٓمٓ ، ذٰلِكَ الْكِتَابُ لَا رَيْبَ فِيْهِ هُدًى لِّلْمُتَّقِيْنَ ، الَّذِيْنَ يُؤْمِنُوْنَ بِالْغَيْبِ وَيُقِيْمُوْنَ الصَّلَاةَ وَمِمَّا رَزَقْنَاهُمْ يُنْفِقُوْنَ ، وَالَّذِيْنَ يُؤْمِنُوْنَ بِمَا أُنْزِلَ إِلَيْكَ وَمَا أُنْزِلَ مِنْ قَبْلِكَ وَبِالْآخِرَةِ هُمْ يُوْقِنُوْنَ ، أُولٰئِكَ عَلَىٰ هُدًى مِنْ رَبِّهِمْ وَأُولٰئِكَ هُمُ الْمُفْلِحُوْنَ`,
    transliteration: `Alif-Lam-Mim. Dhalikal-kitabu la rayba fih, hudal-lil-muttaqin. Alladhina yu'minuna bil-ghaybi wa yuqimunas-salata wa mimma razaqnahum yunfiqun. Walladhina yu'minuna bima unzila ilayka wa ma unzila min qablik, wa bil-akhirati hum yuqinun. Ula'ika 'ala hudam-mir-Rabbihim wa ula'ika humul-muflihun.`,
    translation: `Alif, Lam, Mim. This is the Book about which there is no doubt, a guidance for those conscious of Allah — who believe in the unseen, establish prayer, and spend out of what We have provided for them, and who believe in what has been revealed to you and what was revealed before you, and of the Hereafter they are certain. Those are upon guidance from their Lord, and it is those who are the successful.`,
    hadith_full: `It is reported that the Shaytan will not come near the one who recites the opening verses of Surah Al-Baqarah along with Ayat al-Kursi and the last verses of Al-Baqarah in the morning.`,
  },
  {
    id: 'morning_3', sort_order: 3, recommended_count: 1,
    reward: 'Ayatul Kursi: The Greatest Protection',
    reference: 'Quran 2:255, Hakim 1/562',
    reuse: 'morning_lwa_1',
  },
  {
    id: 'morning_4', sort_order: 4, recommended_count: 1,
    reward: 'La Ikraha fid-Deen: No Compulsion in Religion',
    reference: 'Quran 2:256',
    arabic: `لَا إِكْرَاهَ فِي الدِّيْنِ ، قَدْ تَبَيَّنَ الرُّشْدُ مِنَ الْغَيِّ ، فَمَنْ يَّكْفُرْ بِالطَّاغُوْتِ وَيُؤْمِنْ بِاللّٰهِ فَقَدِ اسْتَمْسَكَ بِالْعُرْوَةِ الْوُثْقَىٰ لَا انْفِصَامَ لَهَا ، وَاللّٰهُ سَمِيْعٌ عَلِيْمٌ`,
    transliteration: `La ikraha fid-din, qad tabayyanar-rushdu minal-ghayy. Faman yakfur bit-taghuti wa yu'min billahi faqadis-tamsaka bil-'urwatil-wuthqa lanfisama laha. Wallahu Sami'un 'Alim.`,
    translation: `There shall be no compulsion in the religion. The right course has become clear from the wrong. So whoever disbelieves in false deities and believes in Allah has grasped the most trustworthy handhold with no break in it. And Allah is Hearing and Knowing.`,
    hadith_full: `This verse establishes the principle that faith must come from sincere conviction. Reciting it in the morning affirms one's conscious choice of Islam and trust in Allah's guidance.`,
  },
  {
    id: 'morning_5', sort_order: 5, recommended_count: 1,
    reward: 'Allah is the Ally of the Believers',
    reference: 'Quran 2:257',
    arabic: `اَللّٰهُ وَلِيُّ الَّذِيْنَ آمَنُوْا يُخْرِجُهُمْ مِّنَ الظُّلُمَاتِ إِلَى النُّوْرِ ، وَالَّذِيْنَ كَفَرُوْا أَوْلِيَاؤُهُمُ الطَّاغُوْتُ يُخْرِجُوْنَهُمْ مِّنَ النُّوْرِ إِلَى الظُّلُمَاتِ ، أُولٰئِكَ أَصْحَابُ النَّارِ هُمْ فِيْهَا خَالِدُوْنَ`,
    transliteration: `Allahu waliyyul-ladhina amanu yukhrijuhum minaz-zulumati ilan-nur. Walladhina kafaru awliya'uhumut-taghut, yukhrijunahum minan-nuri ilaz-zulumat. Ula'ika as-habun-nar, hum fiha khalidun.`,
    translation: `Allah is the ally of those who believe. He brings them out from darknesses into the light. And those who disbelieve — their allies are false deities. They take them out of the light into darknesses. Those are the companions of the Fire; they will abide eternally therein.`,
    hadith_full: `This verse affirms that Allah guides and protects the believers, bringing them from the darkness of ignorance into the light of faith. Reciting it in the morning places oneself under Allah's guardianship for the day.`,
  },
  {
    id: 'morning_6', sort_order: 6, recommended_count: 1,
    reward: 'To Allah Belongs All That Is in the Heavens and Earth',
    reference: 'Quran 2:284',
    arabic: `لِلّٰهِ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ، وَإِنْ تُبْدُوْا مَا فِيْ أَنْفُسِكُمْ أَوْ تُخْفُوْهُ يُحَاسِبْكُمْ بِهِ اللّٰهُ ، فَيَغْفِرُ لِمَنْ يَّشَاءُ وَيُعَذِّبُ مَنْ يَّشَاءُ ، وَاللّٰهُ عَلَىٰ كُلِّ شَيْءٍ قَدِيْرٌ`,
    transliteration: `Lillahi ma fis-samawati wa ma fil-ard. Wa in tubdu ma fi anfusikum aw tukhfuhu yuhasibkum bihillah. Fayaghfiru limay-yasha'u wa yu'adhdhibu may-yasha'. Wallahu 'ala kulli shay'in qadir.`,
    translation: `To Allah belongs whatever is in the heavens and whatever is in the earth. Whether you show what is within yourselves or conceal it, Allah will bring you to account for it. Then He will forgive whom He wills and punish whom He wills, and Allah is over all things competent.`,
    hadith_full: `This is one of the last three verses of Surah Al-Baqarah. The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him." Scholars include 2:284 as part of this protective recitation.`,
  },
  {
    id: 'morning_7', sort_order: 7, recommended_count: 1,
    reward: 'The Messenger Has Believed',
    reference: 'Quran 2:285, Bukhari 5009',
    arabic: `آمَنَ الرَّسُوْلُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَّبِّهِ وَالْمُؤْمِنُوْنَ ، كُلٌّ آمَنَ بِاللّٰهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّنْ رُسُلِهِ ، وَقَالُوْا سَمِعْنَا وَأَطَعْنَا غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيْرُ`,
    transliteration: `Amanar-Rasulu bima unzila ilayhi mir-Rabbihi wal-mu'minun. Kullun amana billahi wa mala'ikatihi wa kutubihi wa rusulih, la nufarriqu bayna ahadim-mir-rusulih. Wa qalu sami'na wa ata'na, ghufranaka Rabbana wa ilaykal-masir.`,
    translation: `The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah and His angels and His books and His messengers, saying, "We make no distinction between any of His messengers." And they say, "We hear and we obey. Grant us Your forgiveness, our Lord, and to You is the final destination."`,
    hadith_full: `Abu Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him."`,
  },
  {
    id: 'morning_8', sort_order: 8, recommended_count: 1,
    reward: 'Allah Does Not Burden a Soul Beyond Capacity',
    reference: 'Quran 2:286, Bukhari 5009',
    arabic: `لَا يُكَلِّفُ اللّٰهُ نَفْسًا إِلَّا وُسْعَهَا ، لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ، رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِيْنَا أَوْ أَخْطَأْنَا ، رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِيْنَ مِنْ قَبْلِنَا ، رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ، وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ، أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِيْنَ`,
    transliteration: `La yukallifullahu nafsan illa wus'aha. Laha ma kasabat wa 'alayha maktasabat. Rabbana la tu'akhidhna in nasina aw akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'alal-ladhina min qablina. Rabbana wa la tuhammilna ma la taqata lana bih. Wa'fu 'anna waghfir lana warhamna. Anta mawlana fansurna 'alal-qawmil-kafirin.`,
    translation: `Allah does not burden a soul beyond that it can bear. It will have the consequence of what good it has gained, and it will bear the consequence of what evil it has earned. "Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people."`,
    hadith_full: `Abu Mas'ud (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him." Muslim reported that when this verse was revealed, Allah said after each supplication in it: "I have done so."`,
  },
  {
    id: 'morning_9', sort_order: 9, recommended_count: 3,
    reward: 'Surah Al-Ikhlas: Sincerity',
    reference: 'Abu Dawud 5082, An-Nasa\'i',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ هُوَ اللّٰهُ أَحَدٌ ، اَللّٰهُ الصَّمَدُ ، لَمْ يَلِدْ وَلَمْ يُوْلَدْ ، وَلَمْ يَكُنْ لَّهُ كُفُوًا أَحَدٌ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to me, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn (Al-Falaq and An-Nas) three times in the morning and evening — they will suffice you against everything."`,
  },
  {
    id: 'morning_10', sort_order: 10, recommended_count: 3,
    reward: 'Surah Al-Falaq: Seek Refuge from Evil',
    reference: 'Abu Dawud 5082',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ أَعُوْذُ بِرَبِّ الْفَلَقِ ، مِنْ شَرِّ مَا خَلَقَ ، وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ، وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ، وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to me, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn (Al-Falaq and An-Nas) three times in the morning and evening — they will suffice you against everything."`,
  },
  {
    id: 'morning_11', sort_order: 11, recommended_count: 3,
    reward: 'Surah An-Nas: Seek Refuge from Whispers',
    reference: 'Abu Dawud 5082',
    arabic: `بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ

قُلْ أَعُوْذُ بِرَبِّ النَّاسِ ، مَلِكِ النَّاسِ ، إِلٰهِ النَّاسِ ، مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ، الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِ ، مِنَ الْجِنَّةِ وَالنَّاسِ`,
    transliteration: `Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.`,
    translation: `In the name of Allah, the Most Gracious, the Most Merciful. Say, "I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer — who whispers in the breasts of mankind — from among the jinn and mankind."`,
    hadith_full: `Abdullah ibn Khubayb (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to me, "Recite Qul Huwa Allahu Ahad and Al-Mu'awwidhatayn (Al-Falaq and An-Nas) three times in the morning and evening — they will suffice you against everything."`,
  },

  // ── Dua Azkar (12-32) ──
  {
    id: 'morning_12', sort_order: 12, recommended_count: 1,
    reward: 'Morning Supplication: Dominion Belongs to Allah',
    reference: 'Muslim 2723',
    reuse: 'morning_lwa_11',
  },
  {
    id: 'morning_13', sort_order: 13, recommended_count: 1,
    reward: 'Upon the Fitrah of Islam',
    reference: 'Ahmad 15360',
    reuse: 'morning_lwa_9',
  },
  {
    id: 'morning_14', sort_order: 14, recommended_count: 1,
    reward: 'By Your Leave We Have Reached the Morning',
    reference: 'Al-Adab al-Mufrad 1199',
    reuse: 'morning_lwa_14',
  },
  {
    id: 'morning_15', sort_order: 15, recommended_count: 3,
    reward: 'Blessings, Well-being and Concealment',
    reference: 'Ibn al-Sunni 41',
    arabic: `اَللّٰهُمَّ إِنِّيْ أَصْبَحْتُ مِنْكَ فِيْ نِعْمَةٍ وَعَافِيَةٍ وَسِتْرٍ ، فَأَتِمَّ عَلَيَّ نِعْمَتَكَ وَعَافِيَتَكَ وَسِتْرَكَ فِي الدُّنْيَا وَالْآخِرَةِ`,
    transliteration: `Allahumma inni asbahtu minka fi ni'matin wa 'afiyatin wa sitr, fa atimma 'alayya ni'mataka wa 'afiyataka wa sitraka fid-dunya wal-akhirah.`,
    translation: `O Allah, I have entered the morning receiving from You blessings, well-being and concealment (of my faults). So complete Your blessings upon me, Your well-being, and Your concealment in this world and the Hereafter.`,
    hadith_full: `Abdullah ibn Umar (رضي الله عنه) reported: The Messenger of Allah (ﷺ) never used to leave this supplication in the morning and evening, asking Allah to complete His blessings, well-being, and concealment of faults upon him in this world and the Hereafter.`,
  },
  {
    id: 'morning_16', sort_order: 16, recommended_count: 1,
    reward: 'Fulfil Your Obligation to Thank Allah',
    reference: 'Abu Dawud 5073',
    reuse: 'morning_lwa_8',
  },
  {
    id: 'morning_17', sort_order: 17, recommended_count: 1,
    reward: 'Praise Befitting Divine Greatness',
    reference: 'Ibn Majah 3801',
    arabic: `يَا رَبِّ لَكَ الْحَمْدُ كَمَا يَنْبَغِيْ لِجَلَالِ وَجْهِكَ وَعَظِيْمِ سُلْطَانِكَ`,
    transliteration: `Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.`,
    translation: `O my Lord, all praise is due to You as befits the Glory of Your Countenance and the Greatness of Your Authority.`,
    hadith_full: `Abdullah ibn Umar (رضي الله عنه) reported: The Prophet (ﷺ) said, "A servant said: 'Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.' The two angels did not know how to record it, so they ascended to the heavens and said: 'Our Lord, Your servant has said something and we do not know how to record it.' Allah — while knowing best what His servant said — asked: 'What did My servant say?' They replied: 'He said: Ya Rabbi lakal-hamdu kama yanbaghi li jalali wajhika wa 'azimi sultanik.' Allah said to them: 'Record it as My servant said it, until he meets Me and I shall reward him for it.'"`,
  },
  {
    id: 'morning_18', sort_order: 18, recommended_count: 3,
    reward: 'Pleased with Allah as Lord',
    reference: 'Abu Dawud 5072, Ahmad 18967',
    arabic: `رَضِيْتُ بِاللّٰهِ رَبًّا ، وَبِالْإِسْلَامِ دِيْنًا ، وَبِمُحَمَّدٍ صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا`,
    transliteration: `Raditu billahi Rabba, wa bil-Islami dina, wa bi-Muhammadin sallallahu 'alayhi wa sallama nabiyya.`,
    translation: `I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (ﷺ) as my Prophet.`,
    hadith_full: `Abu Sallam (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says in the morning and evening: 'Raditu billahi Rabba, wa bil-Islami dina, wa bi-Muhammadin nabiyya' — it is a right upon Allah to please him on the Day of Judgment."`,
  },
  {
    id: 'morning_19', sort_order: 19, recommended_count: 1,
    reward: 'Well-being in this World and the Hereafter',
    reference: 'Ibn Majah 2/323',
    reuse: 'morning_lwa_5',
  },
  {
    id: 'morning_20', sort_order: 20, recommended_count: 3,
    reward: 'SubhanAllah wa bihamdihi: Outweigh All Other Dhikr',
    reference: 'Muslim 2726',
    reuse: 'morning_lwa_24',
  },
  {
    id: 'morning_21', sort_order: 21, recommended_count: 3,
    reward: 'Protect Yourself From All Harm',
    reference: 'Abu Dawud 5088, Tirmidhi 3388',
    reuse: 'morning_lwa_18',
  },
  {
    id: 'morning_22', sort_order: 22, recommended_count: 3,
    reward: 'Seek Refuge from Shirk',
    reference: 'Ahmad 23119',
    arabic: `اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ أَنْ أُشْرِكَ بِكَ وَأَنَا أَعْلَمُ ، وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ`,
    transliteration: `Allahumma inni a'udhu bika an ushrika bika wa ana a'lam, wa astaghfiruka lima la a'lam.`,
    translation: `O Allah, I seek refuge in You from associating anything with You knowingly, and I seek Your forgiveness for what I do not know.`,
    hadith_full: `Ma'qil ibn Yasar (رضي الله عنه) reported: The Prophet (ﷺ) said, "Whoever says 'Allahumma inni a'udhu bika an ushrika bika wa ana a'lam, wa astaghfiruka lima la a'lam' three times, Allah will protect him from shirk."`,
  },
  {
    id: 'morning_23', sort_order: 23, recommended_count: 3,
    reward: 'Protection From All Evil Wherever You Are',
    reference: 'Muslim 2708, Ahmad',
    arabic: `أَعُوْذُ بِكَلِمَاتِ اللّٰهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ`,
    transliteration: `A'udhu bi kalimatillahit-tammati min sharri ma khalaq.`,
    translation: `I seek refuge in the perfect words of Allah from the evil of what He has created.`,
    hadith_full: `Khawlah bint Hakim (رضي الله عنها) reported: The Messenger of Allah (ﷺ) said, "Whoever arrives at a place and says: 'A'udhu bi kalimatillahit-tammati min sharri ma khalaq' — nothing will harm him until he leaves that place."`,
  },
  {
    id: 'morning_24', sort_order: 24, recommended_count: 1,
    reward: 'Knower of the Unseen: Protection from Evil',
    reference: 'Tirmidhi 3392',
    reuse: 'morning_lwa_6',
  },
  {
    id: 'morning_25', sort_order: 25, recommended_count: 1,
    reward: 'Ya Hayyu Ya Qayyum: Rectify All My Affairs',
    reference: 'Hakim 1/545',
    arabic: `يَا حَيُّ يَا قَيُّوْمُ ، بِرَحْمَتِكَ أَسْتَغِيْثُ ، أَصْلِحْ لِيْ شَأْنِيْ كُلَّهُ ، وَلَا تَكِلْنِيْ إِلَىٰ نَفْسِيْ طَرْفَةَ عَيْنٍ`,
    transliteration: `Ya Hayyu ya Qayyumu birahmatika astaghith, aslih li sha'ni kullahu, wa la takilni ila nafsi tarfata 'ayn.`,
    translation: `O Ever-Living, O Sustainer, in Your mercy I seek relief. Rectify all my affairs and do not leave me to myself even for the blink of an eye.`,
    hadith_full: `Anas ibn Malik (رضي الله عنه) reported: The Messenger of Allah (ﷺ) said to Fatimah (رضي الله عنها), "What prevents you from listening to what I advise you? Say in the morning and evening: 'Ya Hayyu ya Qayyumu birahmatika astaghith, aslih li sha'ni kullahu, wa la takilni ila nafsi tarfata 'ayn.'"`,
  },
  {
    id: 'morning_26', sort_order: 26, recommended_count: 1,
    reward: 'Sayyid al-Istighfar: The Best Forgiveness',
    reference: 'Bukhari 6306',
    reuse: 'morning_lwa_3',
  },
  {
    id: 'morning_27', sort_order: 27, recommended_count: 4,
    reward: 'Get Yourself Freed from the Hellfire',
    reference: 'Abu Dawud 5069',
    reuse: 'morning_lwa_13',
  },
  {
    id: 'morning_28', sort_order: 28, recommended_count: 3,
    reward: 'Ask Allah For Good Health and Protection',
    reference: 'Abu Dawud 5090',
    reuse: 'morning_lwa_15',
  },
  {
    id: 'morning_29', sort_order: 29, recommended_count: 7,
    reward: 'Allah Will Suffice You in Everything',
    reference: 'Abu Dawud 5081',
    reuse: 'morning_lwa_16',
  },
  {
    id: 'morning_30', sort_order: 30, recommended_count: 1,
    reward: 'Ask Allah to Bless Your Day',
    reference: 'Abu Dawud 5084',
    reuse: 'morning_lwa_12',
  },
  {
    id: 'morning_31', sort_order: 31, recommended_count: 100,
    reward: 'An Unparalleled Reward',
    reference: 'Bukhari 6403, Muslim',
    reuse: 'morning_lwa_20',
  },
  {
    id: 'morning_32', sort_order: 32, recommended_count: 100,
    reward: 'Get Your Sins Forgiven',
    reference: 'Bukhari 6405, Muslim 2692',
    reuse: 'morning_lwa_19',
  },
];

// Audio URL sources:
// QDC  = download.quranicaudio.com (full surah - Alafasy murattal)
// QV   = audio.qurancdn.com (per-ayah - Alafasy)
// HM   = hisnmuslim.com/audio/ar (Hisnul Muslim dua recitations)
// LWA  = lifewithallah.com (dua recitations)
const _surah = (n) => `https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/${n}.mp3`;
const _ayah  = (s, a) => `https://audio.qurancdn.com/Alafasy/mp3/${String(s).padStart(3,'0')}${String(a).padStart(3,'0')}.mp3`;
const _hm    = (id) => `https://www.hisnmuslim.com/audio/ar/${id}.mp3`;
const morningAudioMap = {
  // ── Quranic passages (Alafasy murattal) ──
  'morning_1':  _surah(1),     // Fatiha — full surah
  // morning_2: Baqarah 2:1-5 — no matching audio available
  'morning_4':  _ayah(2, 256), // 2:256
  'morning_5':  _ayah(2, 257), // 2:257
  'morning_6':  _ayah(2, 284), // 2:284
  'morning_7':  _ayah(2, 285), // 2:285
  'morning_8':  _ayah(2, 286), // 2:286
  'morning_9':  _surah(112),   // Al-Ikhlas — full surah
  'morning_10': _surah(113),   // Al-Falaq — full surah
  'morning_11': _surah(114),   // An-Nas — full surah
  // ── Dua recitations (HM = Hisnul Muslim — all morning wording ✓) ──
  'morning_12': _hm(77),       // Sovereignty "Asbahna wa asbahal-mulku lillah" = HM #77
  'morning_13': _hm(90),       // Fitrah "Asbahna 'ala fitratil-islam" = HM #90
  'morning_14': _hm(78),       // By Your Leave "Allahumma bika asbahna" = HM #78
  // morning_15: Blessings & Concealment — not in HM collection
  'morning_16': _hm(81),       // Gratitude "Allahumma ma asbaha bi min ni'mah" = HM #81
  // morning_17: Ya Rabbi lakal hamdu — not in HM collection
  'morning_18': _hm(87),       // Raditu billahi = HM #87
  'morning_19': _hm(84),       // Well-being "Allahumma inni as'alukal-'afwa" = HM #84
  'morning_20': _hm(94),       // SubhanAllah 'adada khalqihi = HM #94
  'morning_21': _hm(86),       // Bismillah protection = HM #86
  'morning_22': 'https://salafiaudio.files.wordpress.com/2015/07/hisn-al-muslim-audio-dua-203.mp3', // Shirk refuge
  'morning_23': _hm(97),       // Perfect words = HM #97
  'morning_24': _hm(85),       // Knower of unseen = HM #85
  'morning_25': _hm(88),       // Ya Hayyu ya Qayyum = HM #88
  'morning_26': _hm(79),       // Sayyid al-Istighfar = HM #79
  'morning_27': _hm(80),       // Freed from Hellfire = HM #80
  'morning_28': _hm(82),       // Health body/hearing/sight = HM #82
  'morning_29': _hm(83),       // Hasbiyallahu = HM #83
  'morning_30': _hm(89),       // Bless your day "Asbahna...Rabbil-'alamin" = HM #89
  'morning_31': _hm(93),       // La ilaha illallah 100x = HM #93
  'morning_32': _hm(91),       // SubhanAllah wa bihamdihi 100x = HM #91
};

// Build final items
function buildItem(item) {
  if (item.reuse && byId[item.reuse]) {
    const src = byId[item.reuse];
    return {
      id: item.id,
      arabic: item.arabic || src.arabic,
      transliteration: item.transliteration || src.transliteration,
      translation: item.translation || src.translation,
      recommended_count: item.recommended_count,
      category_id: 'morning',
      reward: item.reward,
      reference: item.reference,
      sort_order: item.sort_order,
      hadith_full: item.hadith_full || src.hadith_full || '',
      audio_url: morningAudioMap[item.id] || src.audio_url || null,
    };
  }
  return {
    id: item.id,
    arabic: item.arabic || '',
    transliteration: item.transliteration || '',
    translation: item.translation || '',
    recommended_count: item.recommended_count,
    category_id: 'morning',
    reward: item.reward,
    reference: item.reference,
    sort_order: item.sort_order,
    hadith_full: item.hadith_full || '',
    audio_url: morningAudioMap[item.id] || null,
  };
}

const finalItems = morning.map(item => buildItem(item));

// Generate SQL
const esc = (s) => (s || '').replace(/'/g, "''");
let sql = `-- Morning Azkar Migration: Dua & Adhkar v7.5.0 exact 32-item sequence
-- Run this in Supabase SQL Editor

-- Step 1: Delete old morning azkar
DELETE FROM azkar_items WHERE category_id = 'morning';

-- Step 2: Insert new 32 morning azkar
`;

for (const item of finalItems) {
  sql += `INSERT INTO azkar_items (id, arabic, transliteration, translation, recommended_count, category_id, reward, reference, sort_order, hadith_full${item.audio_url ? ', audio_url' : ''})
VALUES ('${esc(item.id)}', '${esc(item.arabic)}', '${esc(item.transliteration)}', '${esc(item.translation)}', ${item.recommended_count}, 'morning', '${esc(item.reward)}', '${esc(item.reference)}', ${item.sort_order}, '${esc(item.hadith_full)}'${item.audio_url ? `, '${esc(item.audio_url)}'` : ''});\n\n`;
}

sql += `-- Verify
SELECT id, sort_order, reward, recommended_count FROM azkar_items WHERE category_id = 'morning' ORDER BY sort_order;\n`;

fs.writeFileSync('_morning_migration.sql', sql, 'utf-8');

// Update local JSON too
const allItems = JSON.parse(fs.readFileSync('assets/data/azkar.json', 'utf-8'));
const nonMorning = allItems.filter(i => (i.category_id || i.category || '') !== 'morning');
const localItems = finalItems.map(i => ({
  id: i.id, arabic: i.arabic, transliteration: i.transliteration, translation: i.translation,
  recommended_count: i.recommended_count, category: 'morning', reward: i.reward,
  reference: i.reference, sort_order: i.sort_order, hadith_full: i.hadith_full, audio_url: i.audio_url,
}));
fs.writeFileSync('assets/data/azkar.json', JSON.stringify([...nonMorning, ...localItems], null, 2), 'utf-8');

console.log('Generated _morning_migration.sql with', finalItems.length, 'items');
console.log('Updated local azkar.json\n');
finalItems.forEach((f, i) => {
  const ok = f.arabic.length > 10 ? '✓' : '⚠ MISSING';
  console.log(`${i+1}. [x${f.recommended_count}] ${f.reward} ${ok}`);
});
