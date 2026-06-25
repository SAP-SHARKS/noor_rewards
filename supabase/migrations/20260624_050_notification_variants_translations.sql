-- Notification variants: per-locale translations.
--
-- Seeds `notification_variants` with translated copies of the English seed
-- from migration 20260624_020 for 7 non-English locales:
--   ar (Arabic), ur (Urdu), fr (French), id (Indonesian),
--   ms (Malay),  ru (Russian), tr (Turkish)
--
-- One row per (notification_type, locale, variant) — variant count per
-- notification_type matches the English seed so the Edge Function's
-- random-pick odds stay even across locales.
--
-- This migration is idempotent-friendly: it only INSERTs new rows. Admins
-- can later edit/disable/add variants via the admin panel (or by direct
-- UPDATE/INSERT) without conflicting with this seed — re-running this
-- migration would simply add duplicate seed rows, so it should be applied
-- once. The active flag and admin-only RLS policy guard the rest.
--
-- Placeholder tokens ({streak}, {type}, {seeds}, {count}, {surahName},
-- {ayah}, {ptsNeeded}, {nextLevel}, {nextTitle}, {monthName}, {ayahs}, …)
-- are preserved verbatim and remain English/curly-braced — they are
-- substituted at send time by `supabase/functions/_shared/variants.ts`.
--
-- Brand/term notes:
--   "Sabiq"  → kept as-is in every locale (brand name).
--   "Quran"  → القرآن (ar/ur), Coran (fr), Al-Qur'an (id/ms),
--              Коран (ru), Kur'an (tr).
--   "adhkar/dhikr" → ال أذكار/ذكر (ar), اذکار/ذکر (ur), adhkar/dhikr
--              transliteration in latin-script locales as is conventional.

-- ─── Arabic (ar) translations ─────────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'ar', 'حافظ على سلسلتك 🔥', 'سلسلة {type} وصلت إلى {streak} يوماً. نقرة واحدة قبل منتصف الليل تثبّتها.', 'quran'),
('streak_at_risk', 'ar', '{streak} يوماً من الثبات — لا تتوقف الآن', 'قطعت شوطاً طويلاً، لا تكسر سلسلة {type}. افتح سابق واختم يومك.', 'quran'),
('streak_at_risk', 'ar', 'الليلة مهمة', 'إن فاتك اليوم تعود {streak} يوماً من {type} إلى الصفر. دقيقتان تكفي.', 'quran'),
('streak_at_risk', 'ar', 'سلسلتك في خطر', '{streak} يوماً من {type} على المحك. افتح سابق قبل أن ينتهي اليوم.', 'quran'),
('streak_at_risk', 'ar', 'نقرة واحدة تنقذ سلسلتك', 'ثبّت اليوم رقم {streak} من سلسلة {type} — حتى آية واحدة تكفي.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'ar', 'اختم يومك 🌙', 'انقر لتثبيت بذورك قبل أن تنتهي عند منتصف الليل.', 'home'),
('nightly_checkin', 'ar', 'لا تترك بذورك تضيع', 'بذورك غير المثبتة ستُحذف عند منتصف الليل. ثبّتها الآن.', 'home'),
('nightly_checkin', 'ar', 'اختم يومك بالبركة', 'لحظات من الذكر الآن — وختام أجر اليوم.', 'home'),
('nightly_checkin', 'ar', 'حان وقت ختام اليوم', 'ثبّت يومك واحفظ بذورك في سابق قبل منتصف الليل.', 'home'),
('nightly_checkin', 'ar', 'اقترب منتصف الليل', 'اختم رحلة اليوم — بذورك تنتظر التثبيت.', 'home'),

-- community_momentum
('community_momentum', 'ar', 'الأمة تقرأ القرآن 📖', '{count} مؤمناً يقرؤون القرآن الآن. انضم إليهم.', 'quran'),
('community_momentum', 'ar', 'انضم إلى تلاوة الصباح', '{count} شخصاً فتحوا المصحف اليوم. كن رقم {count}+1.', 'quran'),
('community_momentum', 'ar', 'لا تقرأ وحدك', '{count} من الإخوة والأخوات معك في القرآن اليوم. افتح وانضم.', 'quran'),
('community_momentum', 'ar', 'المجتمع معك الآن', '{count} مؤمناً يتلون الآن. آيتك القادمة قد تكون التالية.', 'quran'),
('community_momentum', 'ar', 'كن جزءاً من قراءة اليوم', '{count} شخصاً يقرؤون القرآن. خذ دقيقتين وانضم إليهم.', 'quran'),

-- resume_reading
('resume_reading', 'ar', 'تابع من حيث توقفت', 'توقفت عند {surahName} {ayah}. الآية التالية على بُعد نقرة.', 'quran'),
('resume_reading', 'ar', 'أكمل {surahName}', 'كنت عند الآية {ayah}. افتح وأكمل ما بدأت.', 'quran'),
('resume_reading', 'ar', '{surahName} تنتظرك', 'توقفت عند الآية {ayah}. دقائق معدودة لتُكمل.', 'quran'),
('resume_reading', 'ar', 'آية واحدة أخرى؟', 'تركت {surahName} عند {ayah}. لنقرأ آية أخرى اليوم.', 'quran'),
('resume_reading', 'ar', 'علامتك في {surahName}', 'الآية {ayah} محفوظة لك. افتح سابق وتابع.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'ar', 'ابدأ يومك بالأذكار ☀️', 'دقائق من أذكار الصباح تحفظ يومك كله.', 'morning'),
('morning_azkaar', 'ar', 'ابدأ بقوة', 'أذكار الصباح حصن المؤمن. لا تخرج من بيتك بدونها.', 'morning'),
('morning_azkaar', 'ar', 'افتح يومك بالذكر', 'خذ خمس دقائق لأذكار الصباح — يومك سيشكرك.', 'morning'),
('morning_azkaar', 'ar', 'سبحان الله، صباح الخير 🌅', 'أذكار الصباح تنتظرك. دقيقتان وتكون في حماية الله.', 'morning'),
('morning_azkaar', 'ar', 'حصنك الصباحي', 'حدّد إيقاع يومك — ابدأ بأذكار الصباح.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'ar', 'اختم يومك بالأذكار 🌙', 'اختم يومك بأذكار المساء واكسب بركتها.', 'evening'),
('evening_azkaar', 'ar', 'حان وقت أذكار المساء', 'لحظات من الذكر الآن تختم اليوم بالنور.', 'evening'),
('evening_azkaar', 'ar', 'أذكار المساء تنتظرك', 'خذ خمس دقائق لقراءة أذكار المساء قبل النوم.', 'evening'),
('evening_azkaar', 'ar', 'اختم يومك بشكل صحيح', 'النبي ﷺ لم يكن يفوّت أذكار المساء. اتبع السنة.', 'evening'),
('evening_azkaar', 'ar', 'عادة أخيرة قبل النوم', 'اقرأ أذكار المساء واسترح تحت حفظ الله.', 'evening'),

-- level_up
('level_up', 'ar', '🚀 اقتربت من المستوى {nextLevel}', '{ptsNeeded} بذرة فقط وتصبح {nextTitle}.', 'profile'),
('level_up', 'ar', 'لقب {nextTitle} على بُعد خطوة', '{ptsNeeded} بذرة فقط للوصول إلى المستوى {nextLevel}. لا تتوقف.', 'profile'),
('level_up', 'ar', 'دفعة واحدة، لقب جديد', 'اكسب {ptsNeeded} بذرة اليوم لتفتح {nextTitle}.', 'profile'),
('level_up', 'ar', 'كدت تصل 🏆', '{ptsNeeded} بذرة تفصلك عن المستوى {nextLevel} ({nextTitle}). هيا.', 'profile'),

-- monthly_quran
('monthly_quran', 'ar', 'شهر جديد، صفحة جديدة 📖', '{monthName} بدأ. ضع هدفاً قرآنياً هذا الشهر — حتى آية يومياً تكفي.', 'quran'),
('monthly_quran', 'ar', 'شهر جديد، نية جديدة', 'ابدأ {monthName} بقوة. افتح القرآن اليوم واكتب نيتك.', 'quran'),
('monthly_quran', 'ar', 'اجعل {monthName} هو الشهر', 'أحب الأعمال إلى الله أدومها. ابدأ إيقاعك القرآني اليوم.', 'quran'),
('monthly_quran', 'ar', 'بداية جديدة مع {monthName}', 'الشهر الجديد رحمة. ليكن أول عمل لك هو فتح القرآن.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'ar', 'انظر إلى {monthName} 🌙', 'قرأت {ayahs} آية الشهر الماضي، ما شاء الله. شاهد أثرك الكامل.', 'akhirah'),
('monthly_milestone', 'ar', '{ayahs} آية الشهر الماضي، الحمد لله', 'شاهد كيف يقارن {monthName} مع شهورك السابقة.', 'akhirah'),
('monthly_milestone', 'ar', '{monthName} بالأرقام', '{ayahs} آية. حيوات حقيقية أعنتها. افتح سابق لترى الصورة كاملة.', 'akhirah'),
('monthly_milestone', 'ar', 'شهر من البركة', 'كسبت حسنات {ayahs} آية في {monthName}. شاهد رصيد آخرتك.', 'akhirah');

-- ─── Urdu (ur) translations ───────────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'ur', 'سلسلہ جاری رکھیں 🔥', 'آپ کا {type} سلسلہ {streak} دن تک پہنچ گیا۔ آدھی رات سے پہلے ایک نقر اسے محفوظ کر دے گی۔', 'quran'),
('streak_at_risk', 'ur', '{streak} دن کی مضبوطی — اب نہ رکیں', 'آپ بہت دور آ چکے ہیں، {type} کا سلسلہ نہ توڑیں۔ سابق کھولیں اور آج کا دن مکمل کریں۔', 'quran'),
('streak_at_risk', 'ur', 'آج کی رات اہم ہے', 'آج چھوڑ دیا تو {type} کے {streak} دن صفر ہو جائیں گے۔ دو منٹ کافی ہیں۔', 'quran'),
('streak_at_risk', 'ur', 'آپ کا سلسلہ خطرے میں ہے', '{type} کے {streak} دن داؤ پر ہیں۔ گھڑی بدلنے سے پہلے سابق کھولیں۔', 'quran'),
('streak_at_risk', 'ur', 'ایک نقر، سلسلہ محفوظ', '{type} سلسلے کا دن {streak} پکا کریں — ایک آیت بھی کافی ہے۔', 'quran'),

-- nightly_checkin
('nightly_checkin', 'ur', 'دن کو مہر لگائیں 🌙', 'آدھی رات سے پہلے آج کے بیج تصدیق کرنے کے لیے نقر کریں۔', 'home'),
('nightly_checkin', 'ur', 'بیج ضائع نہ کریں', 'آپ کے غیر محفوظ بیج آدھی رات کو ریسیٹ ہو جائیں گے۔ ابھی تصدیق کریں۔', 'home'),
('nightly_checkin', 'ur', 'دن کا اختتام برکت کے ساتھ', 'چند لمحے کے ذکر سے — آج کا اجر محفوظ کریں۔', 'home'),
('nightly_checkin', 'ur', 'آج کا دن لپیٹنے کا وقت', 'اپنا دن تصدیق کریں اور آدھی رات سے پہلے سابق بیج محفوظ کریں۔', 'home'),
('nightly_checkin', 'ur', 'آدھی رات قریب ہے', 'آج کے سفر کو مکمل کریں — آپ کے بیج تصدیق کے منتظر ہیں۔', 'home'),

-- community_momentum
('community_momentum', 'ur', 'امت قرآن پڑھ رہی ہے 📖', '{count} مومنین ابھی قرآن پڑھ رہے ہیں۔ ان میں شامل ہوں۔', 'quran'),
('community_momentum', 'ur', 'صبح کی تلاوت میں شامل ہوں', 'آج {count} لوگوں نے قرآن کھولا۔ اسے {count}+1 بنائیں۔', 'quran'),
('community_momentum', 'ur', 'اکیلے نہ پڑھیں', 'آج {count} بھائی اور بہنیں آپ کے ساتھ قرآن میں ہیں۔ کھولیں اور شامل ہوں۔', 'quran'),
('community_momentum', 'ur', 'کمیونٹی یہاں ہے', 'ابھی {count} مومنین تلاوت کر رہے ہیں۔ اگلی آیت آپ کی ہو سکتی ہے۔', 'quran'),
('community_momentum', 'ur', 'آج کی پڑھائی کا حصہ بنیں', '{count} لوگ قرآن پڑھ رہے ہیں۔ دو منٹ نکالیں اور شامل ہوں۔', 'quran'),

-- resume_reading
('resume_reading', 'ur', 'جہاں چھوڑا تھا وہاں سے جاری رکھیں', 'آپ {surahName} {ayah} پر رکے تھے۔ اگلی آیت ایک نقر کے فاصلے پر ہے۔', 'quran'),
('resume_reading', 'ur', '{surahName} جاری رکھیں', 'آپ آیت {ayah} پر تھے۔ کھولیں اور جو شروع کیا تھا مکمل کریں۔', 'quran'),
('resume_reading', 'ur', '{surahName} منتظر ہے', 'آپ نے آیت {ayah} پر وقفہ کیا۔ جاری رکھنے کے لیے چند منٹ کافی ہیں۔', 'quran'),
('resume_reading', 'ur', 'ایک اور آیت؟', 'آپ نے {surahName} کو {ayah} پر چھوڑا۔ آج ایک اور پڑھتے ہیں۔', 'quran'),
('resume_reading', 'ur', '{surahName} میں آپ کا نشان', 'آیت {ayah} آپ کے لیے محفوظ ہے۔ سابق کھولیں اور آگے بڑھیں۔', 'quran'),

-- morning_azkaar
('morning_azkaar', 'ur', 'اذکار سے دن کا آغاز ☀️', 'صبح کے ذکر کے چند منٹ آپ کے پورے دن کی حفاظت کرتے ہیں۔', 'morning'),
('morning_azkaar', 'ur', 'مضبوط آغاز کریں', 'صبح کے اذکار مومن کی ڈھال ہیں۔ ان کے بغیر گھر سے نہ نکلیں۔', 'morning'),
('morning_azkaar', 'ur', 'دن کا آغاز ذکر سے کریں', 'صبح کے اذکار کے لیے 5 منٹ نکالیں — آپ کا دن آپ کا شکر گزار ہو گا۔', 'morning'),
('morning_azkaar', 'ur', 'سبحان اللہ، صبح بخیر 🌅', 'صبح کے اذکار منتظر ہیں۔ دو منٹ اور آپ محفوظ ہو جائیں۔', 'morning'),
('morning_azkaar', 'ur', 'آپ کی صبح کی ڈھال', 'آج کا انداز طے کریں — صبح کے اذکار سے شروع کریں۔', 'morning'),

-- evening_azkaar
('evening_azkaar', 'ur', 'اذکار کے ساتھ آرام 🌙', 'شام کے ذکر کے ساتھ دن کو ختم کریں اور اس کی برکت کمائیں۔', 'evening'),
('evening_azkaar', 'ur', 'شام کے ذکر کا وقت', 'ابھی چند لمحے کا ذکر دن کو نور میں مہر لگاتا ہے۔', 'evening'),
('evening_azkaar', 'ur', 'شام کے اذکار منتظر ہیں', 'سونے سے پہلے شام کے اذکار پڑھنے کے لیے 5 منٹ نکالیں۔', 'evening'),
('evening_azkaar', 'ur', 'دن کا صحیح اختتام', 'نبی ﷺ نے کبھی شام کے اذکار نہیں چھوڑے۔ سنت میں شامل ہوں۔', 'evening'),
('evening_azkaar', 'ur', 'سونے سے پہلے ایک اور عادت', 'شام کے اذکار پڑھیں اور اللہ کی حفاظت میں آرام کریں۔', 'evening'),

-- level_up
('level_up', 'ur', '🚀 آپ لیول {nextLevel} کے قریب ہیں', 'صرف {ptsNeeded} مزید بیج اور آپ {nextTitle} بن جائیں گے۔', 'profile'),
('level_up', 'ur', '{nextTitle} کا درجہ بالکل قریب ہے', 'لیول {nextLevel} سے صرف {ptsNeeded} بیج دور۔ اب نہ رکیں۔', 'profile'),
('level_up', 'ur', 'ایک دھکا، ایک نیا لقب', 'آج {ptsNeeded} بیج کمائیں اور {nextTitle} کھولیں۔', 'profile'),
('level_up', 'ur', 'تقریباً پہنچ گئے 🏆', 'آپ اور لیول {nextLevel} ({nextTitle}) کے درمیان {ptsNeeded} بیج۔ چلیں۔', 'profile'),

-- monthly_quran
('monthly_quran', 'ur', 'نیا مہینہ، نیا صفحہ 📖', '{monthName} آ گیا۔ اس مہینے کے لیے قرآنی ہدف بنائیں — روزانہ ایک آیت بھی کافی ہے۔', 'quran'),
('monthly_quran', 'ur', 'نیا مہینہ، نئی نیت', '{monthName} مضبوطی سے شروع کریں۔ آج قرآن کھولیں اور اپنی نیت لکھیں۔', 'quran'),
('monthly_quran', 'ur', '{monthName} کو مہینہ بنائیں', 'بہترین اعمال وہ ہیں جو مستقل ہوں۔ آج اپنی قرآنی ترتیب شروع کریں۔', 'quran'),
('monthly_quran', 'ur', '{monthName} کے لیے ریسیٹ کریں', 'نیا مہینہ رحمت ہے۔ آپ کا پہلا عمل قرآن کھولنا ہو۔', 'quran'),

-- monthly_milestone
('monthly_milestone', 'ur', '{monthName} پر نظر ڈالیں 🌙', 'پچھلے مہینے آپ نے {ayahs} آیات پڑھیں، ماشاء اللہ۔ اپنا مکمل اثر دیکھیں۔', 'akhirah'),
('monthly_milestone', 'ur', 'پچھلے مہینے {ayahs} آیات، الحمد للہ', 'دیکھیں کہ آپ کا {monthName} پچھلے مہینوں سے کیسا ہے۔', 'akhirah'),
('monthly_milestone', 'ur', 'اعداد میں آپ کا {monthName}', '{ayahs} آیات۔ حقیقی زندگیوں کی مدد ہوئی۔ مکمل تصویر دیکھنے کے لیے سابق کھولیں۔', 'akhirah'),
('monthly_milestone', 'ur', 'برکت کا مہینہ', 'آپ نے {monthName} میں {ayahs} آیات کی حسنات کمائیں۔ اپنا آخرت کا بیلنس دیکھیں۔', 'akhirah');

-- ─── French (fr) translations ─────────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'fr', 'Maintiens la chaîne 🔥', 'Ta série {type} atteint {streak} jours. Un tap avant minuit pour la verrouiller.', 'quran'),
('streak_at_risk', 'fr', '{streak} jours de force — n''abandonne pas', 'Tu es venu trop loin pour casser ta série {type}. Ouvre Sabiq et scelle aujourd''hui.', 'quran'),
('streak_at_risk', 'fr', 'Ce soir compte', 'Saute aujourd''hui et {streak} jours de {type} retombent à zéro. Deux minutes suffisent.', 'quran'),
('streak_at_risk', 'fr', 'Ta série est en danger', '{streak} jours de {type} sont en jeu. Ouvre Sabiq avant que l''heure ne tourne.', 'quran'),
('streak_at_risk', 'fr', 'Un tap, série sauvée', 'Verrouille le jour {streak} de ta série {type} — même une seule ayah compte.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'fr', 'Scelle la journée 🌙', 'Touche pour valider les Graines d''aujourd''hui avant qu''elles n''expirent à minuit.', 'home'),
('nightly_checkin', 'fr', 'Ne laisse pas tes Graines filer', 'Tes Graines non réclamées se réinitialisent à minuit. Valide-les maintenant.', 'home'),
('nightly_checkin', 'fr', 'Termine ta journée avec baraka', 'Quelques instants de rappel maintenant — et scelle la récompense du jour.', 'home'),
('nightly_checkin', 'fr', 'Il est temps de boucler', 'Valide ta journée et verrouille tes Graines Sabiq avant minuit.', 'home'),
('nightly_checkin', 'fr', 'Bientôt minuit', 'Scelle le voyage d''aujourd''hui — tes Graines attendent d''être validées.', 'home'),

-- community_momentum
('community_momentum', 'fr', 'La Oumma lit 📖', '{count} croyants lisent le Coran en ce moment. Rejoins-les.', 'quran'),
('community_momentum', 'fr', 'Rejoins la récitation du matin', '{count} personnes ont ouvert le Coran aujourd''hui. Fais-en {count}+1.', 'quran'),
('community_momentum', 'fr', 'Ne lis pas seul', '{count} frères et sœurs sont avec toi dans le Coran aujourd''hui. Ouvre et rejoins.', 'quran'),
('community_momentum', 'fr', 'La communauté est là', '{count} croyants récitent en ce moment. Ton ayah pourrait être la prochaine.', 'quran'),
('community_momentum', 'fr', 'Fais partie de la lecture du jour', '{count} personnes lisent le Coran. Prends 2 minutes et rejoins-les.', 'quran'),

-- resume_reading
('resume_reading', 'fr', 'Reprends là où tu t''es arrêté', 'Tu t''es arrêté à {surahName} {ayah}. La prochaine ayah est à un tap.', 'quran'),
('resume_reading', 'fr', 'Continue {surahName}', 'Tu étais à l''ayah {ayah}. Ouvre et termine ce que tu as commencé.', 'quran'),
('resume_reading', 'fr', '{surahName} t''attend', 'Tu as fait une pause à l''ayah {ayah}. Quelques minutes suffisent pour continuer.', 'quran'),
('resume_reading', 'fr', 'Une ayah de plus ?', 'Tu as laissé {surahName} à {ayah}. Lisons-en une de plus aujourd''hui.', 'quran'),
('resume_reading', 'fr', 'Ton signet dans {surahName}', 'L''ayah {ayah} est gardée pour toi. Ouvre Sabiq pour continuer.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'fr', 'Commence la journée par les adhkar ☀️', 'Quelques minutes de rappel matinal protègent toute ta journée.', 'morning'),
('morning_azkaar', 'fr', 'Démarre en force', 'Les adhkar du matin sont le bouclier du croyant. Ne pars pas sans eux.', 'morning'),
('morning_azkaar', 'fr', 'Ouvre la journée par le dhikr', 'Prends 5 minutes pour les adhkar du matin — ta journée te remerciera.', 'morning'),
('morning_azkaar', 'fr', 'SubhanAllah, bonjour 🌅', 'Les adhkar du matin t''attendent. Deux minutes et te voilà protégé.', 'morning'),
('morning_azkaar', 'fr', 'Ton bouclier matinal', 'Donne le ton de la journée — commence par les adhkar du matin.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'fr', 'Décompresse avec les adhkar 🌙', 'Clôture la journée par le rappel du soir et gagne sa baraka.', 'evening'),
('evening_azkaar', 'fr', 'L''heure du dhikr du soir', 'Quelques instants de rappel scellent maintenant la journée dans la lumière.', 'evening'),
('evening_azkaar', 'fr', 'Les adhkar du soir attendent', 'Prends 5 minutes pour réciter les adhkar du soir avant de dormir.', 'evening'),
('evening_azkaar', 'fr', 'Clôture bien la journée', 'Le Prophète ﷺ n''a jamais manqué ses adhkar du soir. Suis la sounnah.', 'evening'),
('evening_azkaar', 'fr', 'Une habitude avant le coucher', 'Récite les adhkar du soir et repose-toi sous la protection d''Allah.', 'evening'),

-- level_up
('level_up', 'fr', '🚀 Tu approches du Niveau {nextLevel}', 'Encore {ptsNeeded} Graines et tu deviens {nextTitle}.', 'profile'),
('level_up', 'fr', 'Le statut {nextTitle} est juste là', 'À seulement {ptsNeeded} Graines du Niveau {nextLevel}. Ne t''arrête pas.', 'profile'),
('level_up', 'fr', 'Un effort, un nouveau titre', 'Gagne {ptsNeeded} Graines aujourd''hui et débloque {nextTitle}.', 'profile'),
('level_up', 'fr', 'Presque arrivé 🏆', '{ptsNeeded} Graines entre toi et le Niveau {nextLevel} ({nextTitle}). Allons-y.', 'profile'),

-- monthly_quran
('monthly_quran', 'fr', 'Un mois neuf, une page neuve 📖', '{monthName} est là. Fixe un objectif Coran pour ce mois — même une ayah par jour compte.', 'quran'),
('monthly_quran', 'fr', 'Nouveau mois, nouvelle niyyah', 'Commence {monthName} en force. Ouvre le Coran aujourd''hui et écris ton intention.', 'quran'),
('monthly_quran', 'fr', 'Fais de {monthName} le mois', 'Les meilleures œuvres sont les plus constantes. Démarre ton rythme Coran aujourd''hui.', 'quran'),
('monthly_quran', 'fr', 'Recommence pour {monthName}', 'Un nouveau mois est une miséricorde. Que ton premier acte soit d''ouvrir le Coran.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'fr', 'Regarde {monthName} 🌙', 'Tu as lu {ayahs} ayahs le mois dernier, machaAllah. Vois ton impact complet.', 'akhirah'),
('monthly_milestone', 'fr', '{ayahs} ayahs le mois dernier, alhamdoulillah', 'Vois comment ton {monthName} se compare à tes mois passés.', 'akhirah'),
('monthly_milestone', 'fr', 'Ton {monthName} en chiffres', '{ayahs} ayahs. De vraies vies aidées. Ouvre Sabiq pour voir l''ensemble.', 'akhirah'),
('monthly_milestone', 'fr', 'Un mois de baraka', 'Tu as gagné des hassanat pour {ayahs} ayahs en {monthName}. Vois ton bilan akhira.', 'akhirah');

-- ─── Indonesian (id) translations ─────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'id', 'Jaga rantai tetap hidup 🔥', 'Streak {type}-mu sudah {streak} hari. Satu tap sebelum tengah malam untuk menguncinya.', 'quran'),
('streak_at_risk', 'id', '{streak} hari kuat — jangan berhenti sekarang', 'Kamu sudah jauh untuk memutus streak {type}. Buka Sabiq dan kunci hari ini.', 'quran'),
('streak_at_risk', 'id', 'Malam ini penting', 'Lewatkan hari ini dan {streak} hari {type} kembali ke nol. Dua menit cukup.', 'quran'),
('streak_at_risk', 'id', 'Streak-mu dalam bahaya', '{streak} hari {type} dipertaruhkan. Buka Sabiq sebelum jam berubah.', 'quran'),
('streak_at_risk', 'id', 'Satu tap, streak selamat', 'Kunci hari ke-{streak} streak {type}-mu — bahkan satu ayat dihitung.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'id', 'Tutup hari ini 🌙', 'Tap untuk memvalidasi Benih hari ini sebelum kadaluwarsa pukul tengah malam.', 'home'),
('nightly_checkin', 'id', 'Jangan biarkan Benih terbuang', 'Benih yang belum diklaim akan reset tengah malam. Validasi sekarang untuk menjaganya.', 'home'),
('nightly_checkin', 'id', 'Akhiri harimu dengan barakah', 'Sejenak berdzikir sekarang — dan kunci pahala hari ini.', 'home'),
('nightly_checkin', 'id', 'Saatnya menutup hari ini', 'Validasi harimu dan kunci Benih Sabiq sebelum tengah malam.', 'home'),
('nightly_checkin', 'id', 'Hampir tengah malam', 'Tutup perjalanan hari ini — Benihmu menunggu divalidasi.', 'home'),

-- community_momentum
('community_momentum', 'id', 'Umat sedang membaca 📖', '{count} mukmin sedang membaca Al-Qur''an sekarang. Bergabunglah.', 'quran'),
('community_momentum', 'id', 'Gabung tilawah pagi', '{count} orang membuka Al-Qur''an hari ini. Jadikan {count}+1.', 'quran'),
('community_momentum', 'id', 'Jangan membaca sendirian', '{count} saudara dan saudari bersamamu di Al-Qur''an hari ini. Buka dan bergabung.', 'quran'),
('community_momentum', 'id', 'Komunitas ada di sini', '{count} mukmin tilawah sekarang. Ayatmu bisa jadi yang berikutnya.', 'quran'),
('community_momentum', 'id', 'Jadi bagian bacaan hari ini', '{count} orang membaca Al-Qur''an. Luangkan 2 menit dan bergabunglah.', 'quran'),

-- resume_reading
('resume_reading', 'id', 'Lanjutkan dari yang kamu tinggalkan', 'Kamu berhenti di {surahName} {ayah}. Ayat berikutnya hanya satu tap.', 'quran'),
('resume_reading', 'id', 'Lanjutkan {surahName}', 'Kamu di ayat {ayah}. Buka dan selesaikan yang sudah dimulai.', 'quran'),
('resume_reading', 'id', '{surahName} menunggu', 'Kamu berhenti di ayat {ayah}. Hanya beberapa menit untuk lanjut.', 'quran'),
('resume_reading', 'id', 'Satu ayat lagi?', 'Kamu meninggalkan {surahName} di {ayah}. Yuk baca satu lagi hari ini.', 'quran'),
('resume_reading', 'id', 'Penandamu di {surahName}', 'Ayat {ayah} tersimpan untukmu. Buka Sabiq untuk lanjut.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'id', 'Mulai hari dengan dzikir ☀️', 'Beberapa menit dzikir pagi melindungi seharianmu.', 'morning'),
('morning_azkaar', 'id', 'Mulai dengan kuat', 'Dzikir pagi adalah perisai mukmin. Jangan keluar rumah tanpanya.', 'morning'),
('morning_azkaar', 'id', 'Buka hari dengan dzikir', 'Luangkan 5 menit untuk dzikir pagi — harimu akan berterima kasih.', 'morning'),
('morning_azkaar', 'id', 'Subhanallah, selamat pagi 🌅', 'Dzikir pagi menunggumu. Dua menit dan kamu terlindungi.', 'morning'),
('morning_azkaar', 'id', 'Perisai pagimu', 'Tentukan nada hari ini — mulai dengan dzikir pagi.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'id', 'Tenangkan diri dengan dzikir 🌙', 'Tutup hari dengan dzikir petang dan raih barakahnya.', 'evening'),
('evening_azkaar', 'id', 'Saatnya dzikir petang', 'Sejenak berdzikir sekarang menutup hari dalam cahaya.', 'evening'),
('evening_azkaar', 'id', 'Dzikir petang menunggu', 'Luangkan 5 menit untuk membaca dzikir petang sebelum tidur.', 'evening'),
('evening_azkaar', 'id', 'Tutup hari dengan baik', 'Nabi ﷺ tidak pernah meninggalkan dzikir petangnya. Ikuti sunnah.', 'evening'),
('evening_azkaar', 'id', 'Satu kebiasaan sebelum tidur', 'Bacalah dzikir petang dan istirahatlah dalam lindungan Allah.', 'evening'),

-- level_up
('level_up', 'id', '🚀 Kamu dekat dengan Level {nextLevel}', 'Hanya {ptsNeeded} Benih lagi dan kamu menjadi {nextTitle}.', 'profile'),
('level_up', 'id', 'Status {nextTitle} sudah dekat', 'Cuma {ptsNeeded} Benih dari Level {nextLevel}. Jangan berhenti.', 'profile'),
('level_up', 'id', 'Satu dorongan, satu gelar baru', 'Raih {ptsNeeded} Benih hari ini dan buka {nextTitle}.', 'profile'),
('level_up', 'id', 'Hampir sampai 🏆', '{ptsNeeded} Benih antara kamu dan Level {nextLevel} ({nextTitle}). Ayo.', 'profile'),

-- monthly_quran
('monthly_quran', 'id', 'Bulan baru, halaman baru 📖', '{monthName} sudah tiba. Tetapkan target Al-Qur''an bulan ini — bahkan satu ayat sehari berarti.', 'quran'),
('monthly_quran', 'id', 'Bulan baru, niat baru', 'Mulai {monthName} dengan kuat. Buka Al-Qur''an hari ini dan tulis niatmu.', 'quran'),
('monthly_quran', 'id', 'Jadikan {monthName} bulannya', 'Amalan terbaik adalah yang istiqamah. Mulai irama Al-Qur''anmu hari ini.', 'quran'),
('monthly_quran', 'id', 'Reset untuk {monthName}', 'Bulan baru adalah rahmat. Jadikan amal pertamamu membuka Al-Qur''an.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'id', 'Lihat kembali {monthName} 🌙', 'Kamu membaca {ayahs} ayat bulan lalu, masya Allah. Lihat dampak penuhmu.', 'akhirah'),
('monthly_milestone', 'id', '{ayahs} ayat bulan lalu, alhamdulillah', 'Lihat bagaimana {monthName}-mu dibanding bulan-bulan sebelumnya.', 'akhirah'),
('monthly_milestone', 'id', '{monthName}-mu dalam angka', '{ayahs} ayat. Nyawa-nyawa nyata terbantu. Buka Sabiq untuk lihat gambaran penuhnya.', 'akhirah'),
('monthly_milestone', 'id', 'Sebulan penuh barakah', 'Kamu meraih hasanat untuk {ayahs} ayat di {monthName}. Lihat saldo akhiratmu.', 'akhirah');

-- ─── Malay (ms) translations ──────────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'ms', 'Kekalkan rantai 🔥', 'Streak {type} kamu mencecah {streak} hari. Satu ketuk sebelum tengah malam untuk mengunci.', 'quran'),
('streak_at_risk', 'ms', '{streak} hari kukuh — jangan berhenti sekarang', 'Kamu dah jauh untuk patahkan streak {type}. Buka Sabiq dan kunci hari ini.', 'quran'),
('streak_at_risk', 'ms', 'Malam ini penting', 'Lepas hari ini dan {streak} hari {type} kembali kosong. Dua minit memadai.', 'quran'),
('streak_at_risk', 'ms', 'Streak kamu dalam bahaya', '{streak} hari {type} dipertaruhkan. Buka Sabiq sebelum jam berputar.', 'quran'),
('streak_at_risk', 'ms', 'Satu ketuk, streak selamat', 'Kunci hari ke-{streak} streak {type} kamu — satu ayat pun dikira.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'ms', 'Tutup hari 🌙', 'Ketuk untuk sahkan Benih hari ini sebelum tamat tempoh tengah malam.', 'home'),
('nightly_checkin', 'ms', 'Jangan biar Benih hilang', 'Benih yang belum dituntut akan reset tengah malam. Sahkan sekarang.', 'home'),
('nightly_checkin', 'ms', 'Akhiri hari dengan barakah', 'Beberapa saat berzikir sekarang — dan kunci ganjaran hari ini.', 'home'),
('nightly_checkin', 'ms', 'Masa untuk tutup hari', 'Sahkan hari kamu dan kunci Benih Sabiq sebelum tengah malam.', 'home'),
('nightly_checkin', 'ms', 'Hampir tengah malam', 'Tutup perjalanan hari ini — Benih kamu menunggu disahkan.', 'home'),

-- community_momentum
('community_momentum', 'ms', 'Ummah sedang membaca 📖', '{count} mukmin sedang membaca Al-Qur''an sekarang. Sertailah.', 'quran'),
('community_momentum', 'ms', 'Sertai tilawah pagi', '{count} orang buka Al-Qur''an hari ini. Jadikan {count}+1.', 'quran'),
('community_momentum', 'ms', 'Jangan baca seorang diri', '{count} saudara saudari bersama kamu dalam Al-Qur''an hari ini. Buka dan sertai.', 'quran'),
('community_momentum', 'ms', 'Komuniti ada di sini', '{count} mukmin sedang tilawah sekarang. Ayat kamu boleh jadi yang seterusnya.', 'quran'),
('community_momentum', 'ms', 'Jadi sebahagian bacaan hari ini', '{count} orang membaca Al-Qur''an. Luangkan 2 minit dan sertai.', 'quran'),

-- resume_reading
('resume_reading', 'ms', 'Sambung dari tempat kamu berhenti', 'Kamu berhenti di {surahName} {ayah}. Ayat seterusnya hanya satu ketuk.', 'quran'),
('resume_reading', 'ms', 'Sambung {surahName}', 'Kamu berada di ayat {ayah}. Buka dan selesaikan apa yang dimulakan.', 'quran'),
('resume_reading', 'ms', '{surahName} menunggu', 'Kamu berhenti di ayat {ayah}. Cuma beberapa minit untuk sambung.', 'quran'),
('resume_reading', 'ms', 'Satu ayat lagi?', 'Kamu tinggalkan {surahName} di {ayah}. Jom baca satu lagi hari ini.', 'quran'),
('resume_reading', 'ms', 'Penanda kamu dalam {surahName}', 'Ayat {ayah} disimpan untuk kamu. Buka Sabiq untuk terus.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'ms', 'Mulakan hari dengan adhkar ☀️', 'Beberapa minit zikir pagi melindungi sepanjang hari kamu.', 'morning'),
('morning_azkaar', 'ms', 'Mulakan dengan kukuh', 'Adhkar pagi adalah perisai mukmin. Jangan keluar rumah tanpanya.', 'morning'),
('morning_azkaar', 'ms', 'Buka hari dengan zikir', 'Luangkan 5 minit untuk adhkar pagi — hari kamu akan berterima kasih.', 'morning'),
('morning_azkaar', 'ms', 'Subhanallah, selamat pagi 🌅', 'Adhkar pagi menanti. Dua minit dan kamu dilindungi.', 'morning'),
('morning_azkaar', 'ms', 'Perisai pagi kamu', 'Tetapkan nada hari ini — mulakan dengan adhkar pagi.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'ms', 'Tenangkan diri dengan adhkar 🌙', 'Tutup hari dengan zikir petang dan raih barakahnya.', 'evening'),
('evening_azkaar', 'ms', 'Masa zikir petang', 'Beberapa saat berzikir sekarang menutup hari dalam cahaya.', 'evening'),
('evening_azkaar', 'ms', 'Adhkar petang menanti', 'Luangkan 5 minit untuk baca adhkar petang sebelum tidur.', 'evening'),
('evening_azkaar', 'ms', 'Tutup hari dengan betul', 'Nabi ﷺ tidak pernah tinggalkan adhkar petangnya. Ikuti sunnah.', 'evening'),
('evening_azkaar', 'ms', 'Satu tabiat sebelum tidur', 'Baca adhkar petang dan berehat dalam lindungan Allah.', 'evening'),

-- level_up
('level_up', 'ms', '🚀 Kamu hampir Tahap {nextLevel}', 'Hanya {ptsNeeded} Benih lagi dan kamu menjadi {nextTitle}.', 'profile'),
('level_up', 'ms', 'Status {nextTitle} dah dekat', 'Cuma {ptsNeeded} Benih dari Tahap {nextLevel}. Jangan berhenti.', 'profile'),
('level_up', 'ms', 'Satu tolakan, satu gelaran baru', 'Raih {ptsNeeded} Benih hari ini dan buka {nextTitle}.', 'profile'),
('level_up', 'ms', 'Hampir sampai 🏆', '{ptsNeeded} Benih antara kamu dan Tahap {nextLevel} ({nextTitle}). Jom.', 'profile'),

-- monthly_quran
('monthly_quran', 'ms', 'Bulan baru, halaman baru 📖', '{monthName} sudah tiba. Tetapkan sasaran Al-Qur''an bulan ini — satu ayat sehari pun dikira.', 'quran'),
('monthly_quran', 'ms', 'Bulan baru, niat baru', 'Mulakan {monthName} dengan kukuh. Buka Al-Qur''an hari ini dan tulis niat kamu.', 'quran'),
('monthly_quran', 'ms', 'Jadikan {monthName} bulannya', 'Amalan terbaik adalah yang istiqamah. Mulakan rentak Al-Qur''an kamu hari ini.', 'quran'),
('monthly_quran', 'ms', 'Reset untuk {monthName}', 'Bulan baru adalah rahmat. Jadikan amal pertama kamu membuka Al-Qur''an.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'ms', 'Lihat semula {monthName} 🌙', 'Kamu baca {ayahs} ayat bulan lepas, masyaAllah. Lihat impak penuh kamu.', 'akhirah'),
('monthly_milestone', 'ms', '{ayahs} ayat bulan lepas, alhamdulillah', 'Lihat bagaimana {monthName} kamu berbanding bulan-bulan lepas.', 'akhirah'),
('monthly_milestone', 'ms', '{monthName} kamu dalam angka', '{ayahs} ayat. Nyawa sebenar dibantu. Buka Sabiq untuk lihat gambaran penuh.', 'akhirah'),
('monthly_milestone', 'ms', 'Sebulan penuh barakah', 'Kamu meraih hasanat untuk {ayahs} ayat dalam {monthName}. Lihat baki akhirat kamu.', 'akhirah');

-- ─── Russian (ru) translations ────────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'ru', 'Сохрани цепочку 🔥', 'Твоя серия {type} достигла {streak} дней. Одно касание до полуночи зафиксирует её.', 'quran'),
('streak_at_risk', 'ru', '{streak} дней силы — не останавливайся', 'Ты прошёл слишком далеко, чтобы порвать серию {type}. Открой Sabiq и заверши день.', 'quran'),
('streak_at_risk', 'ru', 'Сегодняшний вечер важен', 'Пропусти день — и {streak} дней {type} обнулятся. Две минуты спасут серию.', 'quran'),
('streak_at_risk', 'ru', 'Твоя серия под угрозой', '{streak} дней {type} на кону. Открой Sabiq до полуночи.', 'quran'),
('streak_at_risk', 'ru', 'Одно касание спасёт серию', 'Зафиксируй день {streak} серии {type} — даже один аят считается.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'ru', 'Заверши день 🌙', 'Коснись, чтобы подтвердить сегодняшние Семена до полуночи.', 'home'),
('nightly_checkin', 'ru', 'Не оставляй Семена', 'Неподтверждённые Семена обнулятся в полночь. Подтверди сейчас.', 'home'),
('nightly_checkin', 'ru', 'Заверши день с баракятом', 'Несколько мгновений зикра — и сегодняшняя награда твоя.', 'home'),
('nightly_checkin', 'ru', 'Пора подвести итог', 'Подтверди день и зафиксируй свои Семена Sabiq до полуночи.', 'home'),
('nightly_checkin', 'ru', 'Скоро полночь', 'Заверши путь дня — твои Семена ждут подтверждения.', 'home'),

-- community_momentum
('community_momentum', 'ru', 'Умма читает 📖', '{count} верующих читают Коран прямо сейчас. Присоединяйся.', 'quran'),
('community_momentum', 'ru', 'Присоединись к утренней рецитации', '{count} человек открыли Коран сегодня. Сделай это {count}+1.', 'quran'),
('community_momentum', 'ru', 'Не читай в одиночку', '{count} братьев и сестёр сегодня с тобой в Коране. Открой и присоединись.', 'quran'),
('community_momentum', 'ru', 'Община рядом', '{count} верующих читают прямо сейчас. Твой аят может быть следующим.', 'quran'),
('community_momentum', 'ru', 'Стань частью сегодняшнего чтения', '{count} человек читают Коран. Удели 2 минуты и присоединись.', 'quran'),

-- resume_reading
('resume_reading', 'ru', 'Продолжи с того места, где остановился', 'Ты остановился на {surahName} {ayah}. Следующий аят — в одно касание.', 'quran'),
('resume_reading', 'ru', 'Продолжи {surahName}', 'Ты был на аяте {ayah}. Открой и заверши начатое.', 'quran'),
('resume_reading', 'ru', '{surahName} ждёт', 'Ты сделал паузу на аяте {ayah}. Несколько минут — и продолжишь.', 'quran'),
('resume_reading', 'ru', 'Ещё один аят?', 'Ты оставил {surahName} на {ayah}. Прочитаем ещё один сегодня.', 'quran'),
('resume_reading', 'ru', 'Твоя закладка в {surahName}', 'Аят {ayah} сохранён для тебя. Открой Sabiq, чтобы продолжить.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'ru', 'Начни день с азкара ☀️', 'Несколько минут утреннего зикра защищают весь твой день.', 'morning'),
('morning_azkaar', 'ru', 'Начни сильно', 'Утренний азкар — щит верующего. Не выходи из дома без него.', 'morning'),
('morning_azkaar', 'ru', 'Открой день зикром', 'Удели 5 минут утреннему азкару — твой день поблагодарит тебя.', 'morning'),
('morning_azkaar', 'ru', 'СубханАллах, доброе утро 🌅', 'Утренний азкар ждёт. Две минуты — и ты под защитой.', 'morning'),
('morning_azkaar', 'ru', 'Твой утренний щит', 'Задай тон дню — начни с утреннего азкара.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'ru', 'Отдохни с азкаром 🌙', 'Заверши день вечерним зикром и обрети его баракят.', 'evening'),
('evening_azkaar', 'ru', 'Время вечернего зикра', 'Несколько мгновений зикра сейчас закроют день в свете.', 'evening'),
('evening_azkaar', 'ru', 'Вечерний азкар ждёт', 'Удели 5 минут вечернему азкару перед сном.', 'evening'),
('evening_azkaar', 'ru', 'Заверши день правильно', 'Пророк ﷺ никогда не пропускал вечерний азкар. Следуй сунне.', 'evening'),
('evening_azkaar', 'ru', 'Ещё одна привычка перед сном', 'Прочитай вечерний азкар и отдохни под защитой Аллаха.', 'evening'),

-- level_up
('level_up', 'ru', '🚀 Ты близок к Уровню {nextLevel}', 'Ещё {ptsNeeded} Семян — и ты становишься {nextTitle}.', 'profile'),
('level_up', 'ru', 'Статус {nextTitle} совсем рядом', 'Всего {ptsNeeded} Семян до Уровня {nextLevel}. Не останавливайся.', 'profile'),
('level_up', 'ru', 'Одно усилие — новый титул', 'Заработай {ptsNeeded} Семян сегодня и открой {nextTitle}.', 'profile'),
('level_up', 'ru', 'Почти у цели 🏆', '{ptsNeeded} Семян между тобой и Уровнем {nextLevel} ({nextTitle}). Вперёд.', 'profile'),

-- monthly_quran
('monthly_quran', 'ru', 'Новый месяц, новая страница 📖', '{monthName} наступил. Поставь цель по Корану на этот месяц — даже один аят в день считается.', 'quran'),
('monthly_quran', 'ru', 'Новый месяц, новая ниййа', 'Начни {monthName} сильно. Открой Коран сегодня и запиши намерение.', 'quran'),
('monthly_quran', 'ru', 'Сделай {monthName} тем самым месяцем', 'Лучшие дела — постоянные. Начни ритм с Кораном сегодня.', 'quran'),
('monthly_quran', 'ru', 'Перезагрузка для {monthName}', 'Новый месяц — это милость. Пусть первым делом будет открытие Корана.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'ru', 'Взгляни на {monthName} 🌙', 'В прошлом месяце ты прочитал {ayahs} аятов, машаАллах. Посмотри весь свой вклад.', 'akhirah'),
('monthly_milestone', 'ru', '{ayahs} аятов в прошлом месяце, альхамдулиллях', 'Посмотри, как {monthName} сравнивается с прошлыми месяцами.', 'akhirah'),
('monthly_milestone', 'ru', 'Твой {monthName} в цифрах', '{ayahs} аятов. Настоящим жизням помог. Открой Sabiq, чтобы увидеть полную картину.', 'akhirah'),
('monthly_milestone', 'ru', 'Месяц баракята', 'Ты заработал хасанат за {ayahs} аятов в {monthName}. Посмотри баланс ахира.', 'akhirah');

-- ─── Turkish (tr) translations ────────────────────────────────────────────
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'tr', 'Zinciri canlı tut 🔥', '{type} serin {streak} güne ulaştı. Gece yarısından önce bir dokunuş onu kilitler.', 'quran'),
('streak_at_risk', 'tr', '{streak} gün güçlüsün — şimdi durma', '{type} serini kırmak için çok yol katettin. Sabiq''i aç ve bugünü mühürle.', 'quran'),
('streak_at_risk', 'tr', 'Bu gece önemli', 'Bugünü atla, {streak} günlük {type} sıfıra döner. İki dakika yeter.', 'quran'),
('streak_at_risk', 'tr', 'Serin tehlikede', '{streak} günlük {type} tehlikede. Saat değişmeden Sabiq''i aç.', 'quran'),
('streak_at_risk', 'tr', 'Bir dokunuş, seri güvende', '{type} serinin {streak}. gününü kilitle — bir ayet bile sayılır.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'tr', 'Günü mühürle 🌙', 'Gece yarısından önce dolmadan bugünün Tohumlarını doğrulamak için dokun.', 'home'),
('nightly_checkin', 'tr', 'Tohumları boşa harcama', 'Talep edilmemiş Tohumların gece yarısı sıfırlanır. Şimdi doğrula.', 'home'),
('nightly_checkin', 'tr', 'Günü bereketle bitir', 'Şimdi birkaç anlık zikir — ve bugünün sevabını mühürle.', 'home'),
('nightly_checkin', 'tr', 'Günü kapatma vakti', 'Gününü doğrula ve gece yarısından önce Sabiq Tohumlarını kilitle.', 'home'),
('nightly_checkin', 'tr', 'Gece yarısı yaklaşıyor', 'Bugünün yolculuğunu mühürle — Tohumların doğrulanmayı bekliyor.', 'home'),

-- community_momentum
('community_momentum', 'tr', 'Ümmet okuyor 📖', '{count} mümin şu anda Kur''an okuyor. Onlara katıl.', 'quran'),
('community_momentum', 'tr', 'Sabah tilavetine katıl', 'Bugün {count} kişi Kur''an''ı açtı. Onu {count}+1 yap.', 'quran'),
('community_momentum', 'tr', 'Yalnız okuma', 'Bugün {count} kardeş seninle Kur''an''da. Aç ve katıl.', 'quran'),
('community_momentum', 'tr', 'Topluluk burada', '{count} mümin şu anda tilavet ediyor. Bir sonraki ayet seninki olabilir.', 'quran'),
('community_momentum', 'tr', 'Bugünün okumasının parçası ol', '{count} kişi Kur''an okuyor. 2 dakika ayır ve onlara katıl.', 'quran'),

-- resume_reading
('resume_reading', 'tr', 'Kaldığın yerden devam et', '{surahName} {ayah}''de durdun. Sonraki ayet bir dokunuş uzakta.', 'quran'),
('resume_reading', 'tr', '{surahName}''e devam et', '{ayah}. ayetteydin. Aç ve başladığını bitir.', 'quran'),
('resume_reading', 'tr', '{surahName} bekliyor', '{ayah}. ayette ara verdin. Devam etmek için birkaç dakika yeter.', 'quran'),
('resume_reading', 'tr', 'Bir ayet daha?', '{surahName}''i {ayah}''de bıraktın. Bugün bir tane daha okuyalım.', 'quran'),
('resume_reading', 'tr', '{surahName}''deki yer iminin', '{ayah}. ayet senin için kaydedildi. Devam için Sabiq''i aç.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'tr', 'Güne zikirle başla ☀️', 'Sabah zikrinin birkaç dakikası tüm gününü korur.', 'morning'),
('morning_azkaar', 'tr', 'Güçlü başla', 'Sabah zikri müminin kalkanıdır. Onsuz evden çıkma.', 'morning'),
('morning_azkaar', 'tr', 'Güne zikirle aç', 'Sabah zikrine 5 dakika ayır — günün sana teşekkür edecek.', 'morning'),
('morning_azkaar', 'tr', 'Sübhanallah, günaydın 🌅', 'Sabah zikri bekliyor. İki dakika ve koruma altındasın.', 'morning'),
('morning_azkaar', 'tr', 'Sabah kalkanın', 'Bugünün tonunu belirle — sabah zikriyle başla.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'tr', 'Zikirle rahatla 🌙', 'Akşam zikriyle günü kapat ve bereketini kazan.', 'evening'),
('evening_azkaar', 'tr', 'Akşam zikrinin vakti', 'Şimdi birkaç anlık zikir günü nurla mühürler.', 'evening'),
('evening_azkaar', 'tr', 'Akşam zikri seni bekliyor', 'Uyumadan önce akşam zikrini okumak için 5 dakika ayır.', 'evening'),
('evening_azkaar', 'tr', 'Günü doğru kapat', 'Peygamber ﷺ akşam zikrini hiç bırakmadı. Sünnete uy.', 'evening'),
('evening_azkaar', 'tr', 'Yatmadan bir alışkanlık daha', 'Akşam zikrini oku ve Allah''ın korumasında dinlen.', 'evening'),

-- level_up
('level_up', 'tr', '🚀 {nextLevel}. seviyeye yakınsın', 'Sadece {ptsNeeded} Tohum daha ve {nextTitle} olursun.', 'profile'),
('level_up', 'tr', '{nextTitle} statüsü hemen orada', '{nextLevel}. seviyeye sadece {ptsNeeded} Tohum kaldı. Durma.', 'profile'),
('level_up', 'tr', 'Bir itme, yeni bir unvan', 'Bugün {ptsNeeded} Tohum kazan ve {nextTitle}''i aç.', 'profile'),
('level_up', 'tr', 'Neredeyse vardın 🏆', 'Seninle {nextLevel}. seviye ({nextTitle}) arasında {ptsNeeded} Tohum. Hadi.', 'profile'),

-- monthly_quran
('monthly_quran', 'tr', 'Yeni ay, yeni sayfa 📖', '{monthName} geldi. Bu ay için bir Kur''an hedefi koy — günde bir ayet bile sayılır.', 'quran'),
('monthly_quran', 'tr', 'Yeni ay, yeni niyet', '{monthName}''e güçlü başla. Bugün Kur''an''ı aç ve niyetini yaz.', 'quran'),
('monthly_quran', 'tr', '{monthName}''i o ay yap', 'En hayırlı ameller sürekli olanlardır. Bugün Kur''an ritmine başla.', 'quran'),
('monthly_quran', 'tr', '{monthName} için sıfırla', 'Yeni bir ay rahmettir. İlk amelin Kur''an''ı açmak olsun.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'tr', '{monthName}''e bak 🌙', 'Geçen ay {ayahs} ayet okudun, maşaAllah. Tüm etkini gör.', 'akhirah'),
('monthly_milestone', 'tr', 'Geçen ay {ayahs} ayet, elhamdülillah', '{monthName}''ini önceki aylarınla nasıl karşılaştırdığını gör.', 'akhirah'),
('monthly_milestone', 'tr', 'Rakamlarla {monthName}''in', '{ayahs} ayet. Gerçek hayatlara yardım edildi. Tüm tabloyu görmek için Sabiq''i aç.', 'akhirah'),
('monthly_milestone', 'tr', 'Bereket dolu bir ay', '{monthName}''de {ayahs} ayet için hasenat kazandın. Ahiret bakiyeni gör.', 'akhirah');
