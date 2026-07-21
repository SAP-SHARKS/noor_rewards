-- Notification variants: translations for the 5 push types that only
-- had English rows (daily_astaghfir, salawat_friday, sleep_azkar,
-- habit_gap_dhikr, habit_gap_quran). Before this migration, non-English
-- users were receiving English copy for these types because
-- pickVariant() fell back to the English pool when no locale row
-- existed.
--
-- Covers all 7 non-EN app locales: ar, fr, id, ms, ru, tr, ur.
-- Row counts:
--   daily_astaghfir   5 variants × 7 locales = 35
--   salawat_friday    5 variants × 7 locales = 35
--   sleep_azkar       5 variants × 7 locales = 35
--   habit_gap_dhikr   3 variants × 7 locales = 21
--   habit_gap_quran   3 variants × 7 locales = 21
--   TOTAL                                     147
--
-- Idempotency: pure INSERTs — apply once. Rerunning will duplicate.
-- Dollar-quoted string literals ($sb$...$sb$) sidestep the need to
-- escape embedded apostrophes and quotation marks.

INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- ═══════════════════════════════════════════════════════════════════════
-- daily_astaghfir  (route: dhikr)
-- ═══════════════════════════════════════════════════════════════════════
-- V1 — A moment for istighfar
('daily_astaghfir', 'ur', $sb$استغفار کا ایک لمحہ$sb$, $sb$"استغفر اللہ" دل کو صاف کرتا ہے اور رزق کے دروازے کھولتا ہے۔ ایک منٹ رک کر پڑھیں۔$sb$, 'dhikr'),
('daily_astaghfir', 'ar', $sb$لحظة استغفار$sb$, $sb$"أستغفر الله" تصقل القلب وتفتح أبواب الرزق. توقف دقيقة واذكر.$sb$, 'dhikr'),
('daily_astaghfir', 'fr', $sb$Un instant pour l'istighfar$sb$, $sb$"Astaghfirullah" polit le cœur et ouvre les portes de la subsistance. Fais une pause d'une minute et récite.$sb$, 'dhikr'),
('daily_astaghfir', 'id', $sb$Sesaat untuk istighfar$sb$, $sb$"Astaghfirullah" memoles hati dan membuka pintu rezeki. Berhenti sejenak satu menit dan bacalah.$sb$, 'dhikr'),
('daily_astaghfir', 'ms', $sb$Seketika untuk istighfar$sb$, $sb$"Astaghfirullah" menggilap hati dan membuka pintu rezeki. Berhenti seminit dan lafazkan.$sb$, 'dhikr'),
('daily_astaghfir', 'ru', $sb$Мгновение для истигфара$sb$, $sb$"Астагфируллах" очищает сердце и открывает двери удела. Остановись на минуту и повтори.$sb$, 'dhikr'),
('daily_astaghfir', 'tr', $sb$Bir an istiğfar için$sb$, $sb$"Estağfirullah" kalbi cilalar ve rızık kapılarını açar. Bir dakika dur ve söyle.$sb$, 'dhikr'),

-- V2 — Seek forgiveness
('daily_astaghfir', 'ur', $sb$مغفرت طلب کریں$sb$, $sb$نبی ﷺ دن میں ستر مرتبہ سے زیادہ استغفار کرتے تھے۔ چند لمحوں کا استغفار آپ کا دن بلند کر سکتا ہے۔$sb$, 'dhikr'),
('daily_astaghfir', 'ar', $sb$اطلب المغفرة$sb$, $sb$كان النبي ﷺ يستغفر أكثر من سبعين مرة في اليوم. لحظات من الاستغفار ترفع يومك.$sb$, 'dhikr'),
('daily_astaghfir', 'fr', $sb$Cherche le pardon$sb$, $sb$Le Prophète ﷺ demandait pardon plus de soixante-dix fois par jour. Quelques instants d'istighfar peuvent illuminer ta journée.$sb$, 'dhikr'),
('daily_astaghfir', 'id', $sb$Mohonlah ampun$sb$, $sb$Nabi ﷺ beristighfar lebih dari tujuh puluh kali sehari. Beberapa saat istighfar dapat mengangkat harimu.$sb$, 'dhikr'),
('daily_astaghfir', 'ms', $sb$Pohonlah keampunan$sb$, $sb$Nabi ﷺ beristighfar lebih dari tujuh puluh kali sehari. Beberapa saat istighfar boleh mengangkat hari kamu.$sb$, 'dhikr'),
('daily_astaghfir', 'ru', $sb$Проси прощения$sb$, $sb$Пророк ﷺ просил прощения более семидесяти раз в день. Несколько мгновений истигфара могут возвысить твой день.$sb$, 'dhikr'),
('daily_astaghfir', 'tr', $sb$Bağışlanma dile$sb$, $sb$Peygamber ﷺ günde yetmişten fazla istiğfar ederdi. Birkaç anlık istiğfar günü yükseltebilir.$sb$, 'dhikr'),

-- V3 — The believer's shield
('daily_astaghfir', 'ur', $sb$مومن کی ڈھال$sb$, $sb$استغفار پریشانی دور کرتا ہے، بارش لاتا ہے، مال میں برکت دیتا ہے۔ ابھی کچھ استغفار کریں۔$sb$, 'dhikr'),
('daily_astaghfir', 'ar', $sb$درع المؤمن$sb$, $sb$الاستغفار يذهب الهم ويجلب المطر ويزيد المال. استغفر الآن.$sb$, 'dhikr'),
('daily_astaghfir', 'fr', $sb$Le bouclier du croyant$sb$, $sb$L'istighfar lève l'angoisse, apporte la pluie, multiplie la richesse. Fais-en un peu maintenant.$sb$, 'dhikr'),
('daily_astaghfir', 'id', $sb$Perisai orang beriman$sb$, $sb$Istighfar mengangkat kekhawatiran, mendatangkan hujan, melipatgandakan rezeki. Lakukan sekarang.$sb$, 'dhikr'),
('daily_astaghfir', 'ms', $sb$Perisai orang mukmin$sb$, $sb$Istighfar mengangkat kebimbangan, membawa hujan, menggandakan rezeki. Buatlah sekarang.$sb$, 'dhikr'),
('daily_astaghfir', 'ru', $sb$Щит верующего$sb$, $sb$Истигфар снимает тревогу, приносит дождь, умножает достаток. Соверши сейчас.$sb$, 'dhikr'),
('daily_astaghfir', 'tr', $sb$Müminin kalkanı$sb$, $sb$İstiğfar kaygıyı kaldırır, yağmur getirir, malı bereketlendirir. Şimdi biraz yap.$sb$, 'dhikr'),

-- V4 — Polish the heart
('daily_astaghfir', 'ur', $sb$دل کو صاف کریں$sb$, $sb$ہر گناہ ایک نشان چھوڑتا ہے — استغفار اسے مٹا دیتا ہے۔ نرمی سے "استغفر اللہ و اتوب اليه" پڑھیں۔$sb$, 'dhikr'),
('daily_astaghfir', 'ar', $sb$اجلُ القلب$sb$, $sb$كل ذنب يترك أثراً — والاستغفار يمحوه. اذكر "أستغفر الله وأتوب إليه" بهدوء.$sb$, 'dhikr'),
('daily_astaghfir', 'fr', $sb$Polis le cœur$sb$, $sb$Chaque péché laisse une marque — l'istighfar l'efface. Récite "Astaghfirullah wa atubu ilayh" doucement.$sb$, 'dhikr'),
('daily_astaghfir', 'id', $sb$Poles hatimu$sb$, $sb$Setiap dosa meninggalkan bekas — istighfar menghapusnya. Baca "Astaghfirullah wa atubu ilayh" dengan lembut.$sb$, 'dhikr'),
('daily_astaghfir', 'ms', $sb$Gilap hati$sb$, $sb$Setiap dosa meninggalkan kesan — istighfar menghapuskannya. Lafazkan "Astaghfirullah wa atubu ilayh" dengan lembut.$sb$, 'dhikr'),
('daily_astaghfir', 'ru', $sb$Очисти сердце$sb$, $sb$Каждый грех оставляет след — истигфар стирает его. Повтори "Астагфируллах ва атубу иляйх" тихо.$sb$, 'dhikr'),
('daily_astaghfir', 'tr', $sb$Kalbi cilala$sb$, $sb$Her günah bir iz bırakır — istiğfar onu siler. "Estağfirullah ve etubu ileyh" i sessizce söyle.$sb$, 'dhikr'),

-- V5 — A small habit, immense reward
('daily_astaghfir', 'ur', $sb$چھوٹی عادت، بڑا اجر$sb$, $sb$رک کر "استغفر اللہ" کہیں۔ اپنی سانس کے ساتھ دہرائیں۔ آپ کا رب اسے پسند کرتا ہے۔$sb$, 'dhikr'),
('daily_astaghfir', 'ar', $sb$عادة صغيرة، أجر عظيم$sb$, $sb$توقف وقل "أستغفر الله". كرّرها مع أنفاسك. ربك يحبها.$sb$, 'dhikr'),
('daily_astaghfir', 'fr', $sb$Une petite habitude, une immense récompense$sb$, $sb$Fais une pause et dis "Astaghfirullah". Répète-le au rythme de ta respiration. Ton Seigneur l'aime.$sb$, 'dhikr'),
('daily_astaghfir', 'id', $sb$Kebiasaan kecil, pahala besar$sb$, $sb$Berhentilah sejenak dan ucapkan "Astaghfirullah". Ulangi seiring napasmu. Tuhanmu mencintainya.$sb$, 'dhikr'),
('daily_astaghfir', 'ms', $sb$Tabiat kecil, ganjaran besar$sb$, $sb$Berhenti seketika dan lafazkan "Astaghfirullah". Ulanginya bersama nafas kamu. Tuhan kamu menyukainya.$sb$, 'dhikr'),
('daily_astaghfir', 'ru', $sb$Малая привычка, огромная награда$sb$, $sb$Остановись и скажи "Астагфируллах". Повторяй в такт дыханию. Твой Господь любит это.$sb$, 'dhikr'),
('daily_astaghfir', 'tr', $sb$Küçük bir alışkanlık, büyük bir ödül$sb$, $sb$Dur ve "Estağfirullah" de. Nefesinle tekrar et. Rabbin bunu sever.$sb$, 'dhikr'),

-- ═══════════════════════════════════════════════════════════════════════
-- salawat_friday  (route: dhikr)
-- ═══════════════════════════════════════════════════════════════════════
-- V1 — Salawat on Friday
('salawat_friday', 'ur', $sb$جمعہ کے دن درود$sb$, $sb$آج نبی ﷺ پر کثرت سے درود بھیجیں — جمعہ کے اعمال آپ ﷺ کو دکھائے جاتے ہیں۔$sb$, 'dhikr'),
('salawat_friday', 'ar', $sb$الصلاة على النبي يوم الجمعة$sb$, $sb$أكثر من الصلاة على النبي ﷺ اليوم — أعمال الجمعة تُعرض عليه.$sb$, 'dhikr'),
('salawat_friday', 'fr', $sb$Salawat le vendredi$sb$, $sb$Récite abondamment le salawat sur le Prophète ﷺ aujourd'hui — les actes du vendredi lui sont présentés.$sb$, 'dhikr'),
('salawat_friday', 'id', $sb$Salawat di hari Jumat$sb$, $sb$Bacalah salawat kepada Nabi ﷺ dengan banyak hari ini — amal-amal hari Jumat ditunjukkan kepada beliau.$sb$, 'dhikr'),
('salawat_friday', 'ms', $sb$Selawat di hari Jumaat$sb$, $sb$Bacalah selawat ke atas Nabi ﷺ dengan banyak hari ini — amalan hari Jumaat ditunjukkan kepada baginda.$sb$, 'dhikr'),
('salawat_friday', 'ru', $sb$Салават в пятницу$sb$, $sb$Обильно читай салават на Пророка ﷺ сегодня — дела пятницы ему показываются.$sb$, 'dhikr'),
('salawat_friday', 'tr', $sb$Cuma günü salavat$sb$, $sb$Bugün Peygamber ﷺ üzerine bol bol salavat oku — Cuma amelleri ona arz edilir.$sb$, 'dhikr'),

-- V2 — A Sunnah of Friday
('salawat_friday', 'ur', $sb$جمعہ کی ایک سنت$sb$, $sb$رسول اللہ ﷺ پر درود بھیجیں۔ جتنا زیادہ پڑھیں گے، قیامت کے دن اتنا ہی آپ ﷺ کے قریب ہوں گے۔$sb$, 'dhikr'),
('salawat_friday', 'ar', $sb$سنة من سنن الجمعة$sb$, $sb$صلِّ على الرسول ﷺ. كلما أكثرت، اقترب منك يوم القيامة.$sb$, 'dhikr'),
('salawat_friday', 'fr', $sb$Une Sunnah du vendredi$sb$, $sb$Envoie des bénédictions sur le Messager ﷺ. Plus tu en dis, plus il se rapproche de toi au Jour du Jugement.$sb$, 'dhikr'),
('salawat_friday', 'id', $sb$Sebuah Sunnah Jumat$sb$, $sb$Sampaikan shalawat kepada Rasul ﷺ. Semakin banyak kau ucapkan, semakin dekat beliau denganmu di Hari Kiamat.$sb$, 'dhikr'),
('salawat_friday', 'ms', $sb$Sunnah hari Jumaat$sb$, $sb$Hantarkan selawat ke atas Rasul ﷺ. Semakin banyak kamu ucapkan, semakin dekat baginda dengan kamu di Hari Kiamat.$sb$, 'dhikr'),
('salawat_friday', 'ru', $sb$Сунна пятницы$sb$, $sb$Посылай благословения Посланнику ﷺ. Чем больше произнесёшь, тем ближе он станет к тебе в Судный день.$sb$, 'dhikr'),
('salawat_friday', 'tr', $sb$Cuma sünneti$sb$, $sb$Rasûlullah ﷺ üzerine salavat gönder. Ne kadar çok söylersen, Kıyamet Günü o kadar sana yakın olur.$sb$, 'dhikr'),

-- V3 — Allahumma salli ʿala Muhammad
('salawat_friday', 'ur', $sb$اللہم صلِ علی محمد$sb$, $sb$آج جمعہ ہے — کثرت سے درود پڑھیں۔ ہر ایک درود آپ پر دس رحمتیں لوٹاتا ہے۔$sb$, 'dhikr'),
('salawat_friday', 'ar', $sb$اللهم صلِ على محمد$sb$, $sb$اليوم الجمعة — أكثر من الصلاة على النبي. كل صلاة تعود عليك بعشر رحمات.$sb$, 'dhikr'),
('salawat_friday', 'fr', $sb$Allahumma salli ʿala Muhammad$sb$, $sb$Aujourd'hui c'est vendredi — récite le salawat en abondance. Chacun te rend dix bénédictions.$sb$, 'dhikr'),
('salawat_friday', 'id', $sb$Allahumma salli ʿala Muhammad$sb$, $sb$Hari ini Jumat — bacalah shalawat dengan banyak. Setiap satu mengembalikan sepuluh rahmat kepadamu.$sb$, 'dhikr'),
('salawat_friday', 'ms', $sb$Allahumma salli ʿala Muhammad$sb$, $sb$Hari ini Jumaat — bacalah selawat dengan banyak. Setiap satu memulangkan sepuluh rahmat kepada kamu.$sb$, 'dhikr'),
('salawat_friday', 'ru', $sb$Аллахумма салли ʿала Мухаммад$sb$, $sb$Сегодня пятница — читай салават обильно. Каждый возвращает тебе десять благословений.$sb$, 'dhikr'),
('salawat_friday', 'tr', $sb$Allahümme salli ʿalâ Muhammed$sb$, $sb$Bugün Cuma — bol bol salavat getir. Her biri sana on rahmet olarak döner.$sb$, 'dhikr'),

-- V4 — Light up your Friday
('salawat_friday', 'ur', $sb$اپنے جمعہ کو منور کریں$sb$, $sb$آج نبی ﷺ پر درود پڑھنا سب سے محبوب اعمال میں سے ہے۔ اس گھڑی کو نہ گزرنے دیں۔$sb$, 'dhikr'),
('salawat_friday', 'ar', $sb$أنِر جمعتك$sb$, $sb$الصلاة على النبي ﷺ اليوم من أحب الأعمال. لا تدع هذه الساعة تفوت.$sb$, 'dhikr'),
('salawat_friday', 'fr', $sb$Illumine ton vendredi$sb$, $sb$Dire le salawat sur le Prophète ﷺ aujourd'hui est parmi les actes les plus aimés. Ne laisse pas cette heure passer.$sb$, 'dhikr'),
('salawat_friday', 'id', $sb$Terangi hari Jumatmu$sb$, $sb$Membaca shalawat kepada Nabi ﷺ hari ini adalah amalan yang paling dicintai. Jangan biarkan jam ini berlalu.$sb$, 'dhikr'),
('salawat_friday', 'ms', $sb$Sinari hari Jumaat kamu$sb$, $sb$Berselawat ke atas Nabi ﷺ hari ini adalah antara amalan paling dicintai. Jangan biarkan waktu ini berlalu.$sb$, 'dhikr'),
('salawat_friday', 'ru', $sb$Освети свою пятницу$sb$, $sb$Произнесение салавата на Пророка ﷺ сегодня — из самых любимых дел. Не дай этому часу пройти.$sb$, 'dhikr'),
('salawat_friday', 'tr', $sb$Cumanı aydınlat$sb$, $sb$Bugün Peygamber ﷺ üzerine salavat söylemek en sevilen amellerdendir. Bu saatin geçmesine izin verme.$sb$, 'dhikr'),

-- V5 — For every salawat, ten
('salawat_friday', 'ur', $sb$ہر درود کے بدلے دس$sb$, $sb$"جس نے مجھ پر ایک درود بھیجا، اللہ اس پر دس رحمتیں بھیجتا ہے۔" آج کثرت سے پڑھیں۔$sb$, 'dhikr'),
('salawat_friday', 'ar', $sb$لكل صلاة عشر$sb$, $sb$"من صلى عليّ صلاةً واحدة صلى الله عليه عشراً." أكثر من الصلاة اليوم.$sb$, 'dhikr'),
('salawat_friday', 'fr', $sb$Pour chaque salawat, dix$sb$, $sb$"Quiconque envoie un salawat sur moi, Allah lui en envoie dix." Récite abondamment aujourd'hui.$sb$, 'dhikr'),
('salawat_friday', 'id', $sb$Untuk setiap shalawat, sepuluh$sb$, $sb$"Barangsiapa mengirim satu shalawat kepadaku, Allah mengirim sepuluh kepadanya." Bacalah dengan banyak hari ini.$sb$, 'dhikr'),
('salawat_friday', 'ms', $sb$Untuk setiap selawat, sepuluh$sb$, $sb$"Barangsiapa berselawat sekali ke atasku, Allah berselawat ke atasnya sepuluh kali." Bacalah dengan banyak hari ini.$sb$, 'dhikr'),
('salawat_friday', 'ru', $sb$За каждый салават — десять$sb$, $sb$"Кто пошлёт мне один салават, Аллах пошлёт ему десять." Читай обильно сегодня.$sb$, 'dhikr'),
('salawat_friday', 'tr', $sb$Her salavata karşılık on$sb$, $sb$"Kim bana bir salavat getirirse, Allah ona on rahmet gönderir." Bugün bol bol oku.$sb$, 'dhikr'),

-- ═══════════════════════════════════════════════════════════════════════
-- sleep_azkar  (route: dhikr)
-- ═══════════════════════════════════════════════════════════════════════
-- V1 — Time to wind down
('sleep_azkar', 'ur', $sb$آرام کا وقت$sb$, $sb$دن کا اختتام سونے کے اذکار سے کریں — آیۃ الکرسی، تینوں قل، اور سونے کی دعائیں۔ اللہ کی حفاظت میں سوئیں۔$sb$, 'dhikr'),
('sleep_azkar', 'ar', $sb$وقت الاستراحة$sb$, $sb$اختم يومك بأذكار النوم — آية الكرسي، والمعوذات الثلاث، وأدعية النوم. نم في حفظ الله.$sb$, 'dhikr'),
('sleep_azkar', 'fr', $sb$Il est temps de te détendre$sb$, $sb$Termine la journée avec les adhkar du coucher — Ayat al-Kursi, les 3 Quls, et les du'as du sommeil. Dors sous la protection d'Allah.$sb$, 'dhikr'),
('sleep_azkar', 'id', $sb$Saatnya beristirahat$sb$, $sb$Akhiri hari dengan adzkar tidur — Ayatul Kursi, 3 Quls, dan doa sebelum tidur. Tidurlah dalam perlindungan Allah.$sb$, 'dhikr'),
('sleep_azkar', 'ms', $sb$Masa untuk berehat$sb$, $sb$Akhiri hari dengan adhkar tidur — Ayatul Kursi, 3 Quls, dan doa sebelum tidur. Tidurlah dalam perlindungan Allah.$sb$, 'dhikr'),
('sleep_azkar', 'ru', $sb$Время отдохнуть$sb$, $sb$Заверши день азкарами сна — Аятуль Курси, 3 Кулями, дуа перед сном. Спи под защитой Аллаха.$sb$, 'dhikr'),
('sleep_azkar', 'tr', $sb$Sakinleşme vakti$sb$, $sb$Günü uyku ezkarıyla bitir — Âyetü'l-Kürsî, 3 Kul ve yatmadan önceki dualar. Allah'ın korumasında uyu.$sb$, 'dhikr'),

-- V2 — Seal the night
('sleep_azkar', 'ur', $sb$رات کو مہر لگائیں$sb$, $sb$سونے سے پہلے سورۃ الملک پڑھیں — قبر کی محافظ۔ چند منٹ کے بدلے تاعمر برکت۔$sb$, 'dhikr'),
('sleep_azkar', 'ar', $sb$اختم ليلتك$sb$, $sb$قبل النوم، اقرأ سورة الملك — المنجية من عذاب القبر. دقائق معدودة لبركة العمر كله.$sb$, 'dhikr'),
('sleep_azkar', 'fr', $sb$Scelle la nuit$sb$, $sb$Avant de dormir, récite Sourate Al-Mulk — la protectrice de la tombe. Quelques minutes pour une baraka toute une vie.$sb$, 'dhikr'),
('sleep_azkar', 'id', $sb$Meterai malam$sb$, $sb$Sebelum tidur, bacalah Surah Al-Mulk — pelindung kubur. Beberapa menit untuk barakah seumur hidup.$sb$, 'dhikr'),
('sleep_azkar', 'ms', $sb$Meterai malam$sb$, $sb$Sebelum tidur, bacalah Surah Al-Mulk — pelindung kubur. Beberapa minit untuk barakah seumur hidup.$sb$, 'dhikr'),
('sleep_azkar', 'ru', $sb$Запечатай ночь$sb$, $sb$Перед сном прочти Суру Аль-Мульк — защитницу могилы. Несколько минут ради баракята на всю жизнь.$sb$, 'dhikr'),
('sleep_azkar', 'tr', $sb$Geceyi mühürle$sb$, $sb$Uyumadan önce Mülk Suresi'ni oku — kabrin koruyucusu. Bir ömür bereket için birkaç dakika.$sb$, 'dhikr'),

-- V3 — A peaceful close
('sleep_azkar', 'ur', $sb$پُرسکون اختتام$sb$, $sb$آج رات سونے کے اذکار پڑھیں — آیۃ الکرسی صبح تک مومن کی روح کی حفاظت کرتی ہے۔$sb$, 'dhikr'),
('sleep_azkar', 'ar', $sb$ختام هادئ$sb$, $sb$اقرأ أذكار النوم الليلة — آية الكرسي تحفظ روح المؤمن حتى الصباح.$sb$, 'dhikr'),
('sleep_azkar', 'fr', $sb$Une clôture paisible$sb$, $sb$Récite les adhkar du coucher ce soir — Ayat al-Kursi garde l'âme du croyant jusqu'au matin.$sb$, 'dhikr'),
('sleep_azkar', 'id', $sb$Penutupan yang damai$sb$, $sb$Bacalah adzkar sebelum tidur malam ini — Ayatul Kursi menjaga jiwa mukmin sampai pagi.$sb$, 'dhikr'),
('sleep_azkar', 'ms', $sb$Penutup yang tenang$sb$, $sb$Bacalah adhkar sebelum tidur malam ini — Ayatul Kursi menjaga roh mukmin hingga pagi.$sb$, 'dhikr'),
('sleep_azkar', 'ru', $sb$Мирное завершение$sb$, $sb$Прочти азкар перед сном сегодня — Аятуль Курси охраняет душу верующего до утра.$sb$, 'dhikr'),
('sleep_azkar', 'tr', $sb$Huzurlu bir kapanış$sb$, $sb$Bu gece yatak zikirlerini oku — Âyetü'l-Kürsî mümin ruhunu sabaha dek korur.$sb$, 'dhikr'),

-- V4 — 3 Quls before bed
('sleep_azkar', 'ur', $sb$سونے سے پہلے تین قل$sb$, $sb$فلق، ناس، اخلاص — ہر ایک تین بار، پھر اپنے آپ پر پھونک لیں۔ نبی ﷺ کی سنت۔$sb$, 'dhikr'),
('sleep_azkar', 'ar', $sb$المعوذات الثلاث قبل النوم$sb$, $sb$الفلق، الناس، الإخلاص — ثلاث مرات لكل، ثم امسح جسدك. سنة النبي ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'fr', $sb$Les 3 Quls avant de dormir$sb$, $sb$Al-Falaq, An-Nas, Al-Ikhlas — trois fois chacune, puis passe la main sur ton corps. Une Sunnah du Prophète ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'id', $sb$3 Quls sebelum tidur$sb$, $sb$Al-Falaq, An-Naas, Al-Ikhlas — masing-masing tiga kali, lalu usaplah tubuhmu. Sunnah Nabi ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'ms', $sb$3 Quls sebelum tidur$sb$, $sb$Al-Falaq, An-Naas, Al-Ikhlas — tiga kali setiap satu, kemudian sapulah tubuh kamu. Sunnah Nabi ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'ru', $sb$3 Кулей перед сном$sb$, $sb$Аль-Фаляк, Ан-Нас, Аль-Ихляс — по три раза каждую, затем оботри себя. Сунна Пророка ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'tr', $sb$Yatmadan önce 3 Kul$sb$, $sb$Felak, Nas, İhlas — her biri üç kez, sonra vücuduna sür. Peygamber ﷺ'in sünneti.$sb$, 'dhikr'),

-- V5 — Last call before bed
('sleep_azkar', 'ur', $sb$سونے سے پہلے آخری موقع$sb$, $sb$آپ کے رات کے اذکار منتظر ہیں۔ دن کو ویسے ختم کریں جیسے نبی ﷺ نے کیا۔$sb$, 'dhikr'),
('sleep_azkar', 'ar', $sb$آخر نداء قبل النوم$sb$, $sb$أذكار الليل تنتظرك. اختم يومك كما ختمه النبي ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'fr', $sb$Dernier appel avant de dormir$sb$, $sb$Tes adhkar de la nuit t'attendent. Termine la journée comme le Prophète ﷺ le faisait.$sb$, 'dhikr'),
('sleep_azkar', 'id', $sb$Panggilan terakhir sebelum tidur$sb$, $sb$Adzkar malammu sedang menanti. Akhiri hari sebagaimana Nabi ﷺ mengakhirinya.$sb$, 'dhikr'),
('sleep_azkar', 'ms', $sb$Panggilan terakhir sebelum tidur$sb$, $sb$Adhkar malam kamu sedang menunggu. Akhiri hari sebagaimana Nabi ﷺ akhiri.$sb$, 'dhikr'),
('sleep_azkar', 'ru', $sb$Последний зов перед сном$sb$, $sb$Твои ночные азкары ждут. Заверши день так, как это делал Пророк ﷺ.$sb$, 'dhikr'),
('sleep_azkar', 'tr', $sb$Yatmadan önce son çağrı$sb$, $sb$Gece ezkarların bekliyor. Peygamber ﷺ'in yaptığı gibi günü bitir.$sb$, 'dhikr'),

-- ═══════════════════════════════════════════════════════════════════════
-- habit_gap_dhikr  (route: dhikr)
-- ═══════════════════════════════════════════════════════════════════════
-- V1 — Pair the Quran with dhikr
('habit_gap_dhikr', 'ur', $sb$قرآن کے ساتھ ذکر جوڑیں$sb$, $sb$ماشاءاللہ آپ لگاتار قرآن پڑھ رہے ہیں! صبح یا شام کے اذکار سے اپنے دن کا تاج بنائیں۔$sb$, 'dhikr'),
('habit_gap_dhikr', 'ar', $sb$اجمع القرآن مع الذكر$sb$, $sb$ما شاء الله — تقرأ القرآن باستمرار! توّج يومك بأذكار الصباح أو المساء.$sb$, 'dhikr'),
('habit_gap_dhikr', 'fr', $sb$Associe le Coran au dhikr$sb$, $sb$Ma sha Allah, tu lis le Coran avec constance ! Couronne ta journée avec les adhkar du matin ou du soir.$sb$, 'dhikr'),
('habit_gap_dhikr', 'id', $sb$Padukan Quran dengan dzikir$sb$, $sb$MashaAllah, kamu membaca Quran dengan istiqamah! Mahkotai harimu dengan adzkar pagi atau petang.$sb$, 'dhikr'),
('habit_gap_dhikr', 'ms', $sb$Padankan Quran dengan zikir$sb$, $sb$MashaAllah, anda konsisten membaca Quran! Mahkotakan hari anda dengan adhkar pagi atau petang.$sb$, 'dhikr'),
('habit_gap_dhikr', 'ru', $sb$Соедини Коран с зикром$sb$, $sb$МашаАллах, ты постоянно читаешь Коран! Увенчай свой день утренним или вечерним азкаром.$sb$, 'dhikr'),
('habit_gap_dhikr', 'tr', $sb$Kur'an'ı zikirle birleştir$sb$, $sb$MaşaAllah, düzenli olarak Kur'an okuyorsun! Gününü sabah veya akşam ezkarıyla taçlandır.$sb$, 'dhikr'),

-- V2 — Don't forget remembrance
('habit_gap_dhikr', 'ur', $sb$ذکر کو نہ بھولیں$sb$, $sb$وہ قاری جو ذکر چھوڑ دے، پانی کے بغیر درخت کی طرح ہے۔ اذکار پڑھنے کے لیے ابھی نقر کریں۔$sb$, 'dhikr'),
('habit_gap_dhikr', 'ar', $sb$لا تنسَ الذكر$sb$, $sb$قارئ يترك الذكر كشجرة بلا ماء. انقر لتذكر أذكارك الآن.$sb$, 'dhikr'),
('habit_gap_dhikr', 'fr', $sb$N'oublie pas le rappel$sb$, $sb$Un lecteur qui néglige le dhikr est comme un arbre sans eau. Tape pour réciter tes adhkar maintenant.$sb$, 'dhikr'),
('habit_gap_dhikr', 'id', $sb$Jangan lupakan dzikir$sb$, $sb$Pembaca yang meninggalkan dzikir seperti pohon tanpa air. Ketuk untuk membaca adzkarmu sekarang.$sb$, 'dhikr'),
('habit_gap_dhikr', 'ms', $sb$Jangan lupa zikir$sb$, $sb$Pembaca yang meninggalkan zikir bagai pokok tanpa air. Ketuk untuk baca adhkar kamu sekarang.$sb$, 'dhikr'),
('habit_gap_dhikr', 'ru', $sb$Не забывай зикр$sb$, $sb$Читающий, оставивший зикр, — как дерево без воды. Коснись, чтобы прочесть азкары сейчас.$sb$, 'dhikr'),
('habit_gap_dhikr', 'tr', $sb$Zikri unutma$sb$, $sb$Zikri bırakan bir okuyucu, susuz bir ağaç gibidir. Şimdi ezkarını okumak için dokun.$sb$, 'dhikr'),

-- V3 — Two wings of worship
('habit_gap_dhikr', 'ur', $sb$عبادت کے دو پر$sb$, $sb$قرآن اور ذکر مل کر دل کو بلند کرتے ہیں۔ آپ کے پاس ایک پر ہے — دوسرا بھی جوڑیں۔$sb$, 'dhikr'),
('habit_gap_dhikr', 'ar', $sb$جناحا العبادة$sb$, $sb$القرآن والذكر يرفعان القلب معاً. لديك جناح واحد — أضِف الآخر.$sb$, 'dhikr'),
('habit_gap_dhikr', 'fr', $sb$Les deux ailes de l'adoration$sb$, $sb$Coran et dhikr élèvent le cœur ensemble. Tu as une aile — ajoute l'autre.$sb$, 'dhikr'),
('habit_gap_dhikr', 'id', $sb$Dua sayap ibadah$sb$, $sb$Quran dan dzikir mengangkat hati bersama. Kamu punya satu sayap — tambahkan yang lain.$sb$, 'dhikr'),
('habit_gap_dhikr', 'ms', $sb$Dua sayap ibadah$sb$, $sb$Quran dan zikir mengangkat hati bersama-sama. Kamu ada satu sayap — tambah yang lain.$sb$, 'dhikr'),
('habit_gap_dhikr', 'ru', $sb$Два крыла поклонения$sb$, $sb$Коран и зикр вместе поднимают сердце. У тебя есть одно крыло — добавь второе.$sb$, 'dhikr'),
('habit_gap_dhikr', 'tr', $sb$İbadetin iki kanadı$sb$, $sb$Kur'an ve zikir kalbi birlikte yükseltir. Bir kanadın var — diğerini de ekle.$sb$, 'dhikr'),

-- ═══════════════════════════════════════════════════════════════════════
-- habit_gap_quran  (route: quran)
-- ═══════════════════════════════════════════════════════════════════════
-- V1 — Open the Mushaf today
('habit_gap_quran', 'ur', $sb$آج مصحف کھولیں$sb$, $sb$الحمد للہ آپ کا ذکر مستقل ہے۔ قرآن کے لیے بھی چند منٹ نکالیں — ایک آیت بھی شمار ہوتی ہے۔$sb$, 'quran'),
('habit_gap_quran', 'ar', $sb$افتح المصحف اليوم$sb$, $sb$الحمد لله، ذكرك ثابت. خذ دقائق للقرآن أيضاً — حتى آية واحدة تُحسب.$sb$, 'quran'),
('habit_gap_quran', 'fr', $sb$Ouvre le Mus'haf aujourd'hui$sb$, $sb$Ton dhikr est régulier, alhamdulillah. Prends quelques minutes pour le Coran aussi — même une ayah compte.$sb$, 'quran'),
('habit_gap_quran', 'id', $sb$Buka Mushaf hari ini$sb$, $sb$Alhamdulillah, dzikirmu istiqamah. Luangkan waktu beberapa menit untuk Quran juga — satu ayat pun berarti.$sb$, 'quran'),
('habit_gap_quran', 'ms', $sb$Buka Mushaf hari ini$sb$, $sb$Alhamdulillah, zikir kamu istiqamah. Luangkan beberapa minit untuk Quran juga — satu ayat pun dikira.$sb$, 'quran'),
('habit_gap_quran', 'ru', $sb$Открой Мусхаф сегодня$sb$, $sb$Твой зикр стабилен, альхамдулиллях. Удели несколько минут и Корану — даже один аят засчитывается.$sb$, 'quran'),
('habit_gap_quran', 'tr', $sb$Bugün Mushaf'ı aç$sb$, $sb$Zikrin düzenli, elhamdülillah. Kur'an için de birkaç dakika ayır — bir ayet bile sayılır.$sb$, 'quran'),

-- V2 — The Quran is calling
('habit_gap_quran', 'ur', $sb$قرآن پکار رہا ہے$sb$, $sb$آپ نے کچھ دن سے نہیں پڑھا۔ صرف ایک صفحہ، ایک آیت — جہاں چھوڑا تھا وہاں سے شروع کریں۔$sb$, 'quran'),
('habit_gap_quran', 'ar', $sb$القرآن يناديك$sb$, $sb$لم تقرأ منذ أيام. صفحة واحدة، آية واحدة — ابدأ من حيث توقفت.$sb$, 'quran'),
('habit_gap_quran', 'fr', $sb$Le Coran t'appelle$sb$, $sb$Tu n'as pas lu depuis quelques jours. Une seule page, une seule ayah — reprends là où tu t'es arrêté.$sb$, 'quran'),
('habit_gap_quran', 'id', $sb$Al-Quran memanggilmu$sb$, $sb$Sudah beberapa hari kamu tidak membaca. Satu halaman, satu ayat — mulailah dari tempat kamu berhenti.$sb$, 'quran'),
('habit_gap_quran', 'ms', $sb$Al-Quran memanggil kamu$sb$, $sb$Sudah beberapa hari kamu tidak membaca. Satu muka surat, satu ayat — mulakan dari tempat kamu berhenti.$sb$, 'quran'),
('habit_gap_quran', 'ru', $sb$Коран зовёт$sb$, $sb$Ты не читал несколько дней. Одна страница, один аят — начни там, где остановился.$sb$, 'quran'),
('habit_gap_quran', 'tr', $sb$Kur'an seni çağırıyor$sb$, $sb$Birkaç gündür okumadın. Sadece bir sayfa, bir ayet — kaldığın yerden başla.$sb$, 'quran'),

-- V3 — Pair them together
('habit_gap_quran', 'ur', $sb$دونوں کو جوڑیں$sb$, $sb$ذکر آپ کا روزانہ کا ساتھی ہے۔ قرآن کو بھی بنائیں — ابھی اپنا مصحف کھولیں۔$sb$, 'quran'),
('habit_gap_quran', 'ar', $sb$اجمعهما$sb$, $sb$الذكر رفيقك اليومي. اجعل القرآن كذلك — افتح مصحفك الآن.$sb$, 'quran'),
('habit_gap_quran', 'fr', $sb$Associe-les$sb$, $sb$Le dhikr est ton compagnon quotidien. Fais du Coran un aussi — ouvre ton Mus'haf maintenant.$sb$, 'quran'),
('habit_gap_quran', 'id', $sb$Padukan keduanya$sb$, $sb$Dzikir adalah teman harianmu. Jadikan Quran juga demikian — buka Mushafmu sekarang.$sb$, 'quran'),
('habit_gap_quran', 'ms', $sb$Padankan kedua-duanya$sb$, $sb$Zikir adalah teman harian kamu. Jadikan Quran juga demikian — buka Mushaf kamu sekarang.$sb$, 'quran'),
('habit_gap_quran', 'ru', $sb$Соедини их вместе$sb$, $sb$Зикр — твой ежедневный спутник. Пусть Коран станет им тоже — открой свой Мусхаф сейчас.$sb$, 'quran'),
('habit_gap_quran', 'tr', $sb$İkisini birleştir$sb$, $sb$Zikir günlük yoldaşın. Kur'an'ı da öyle yap — Mushaf'ını şimdi aç.$sb$, 'quran');
