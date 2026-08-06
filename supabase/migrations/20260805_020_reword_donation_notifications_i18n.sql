-- Reword validate_seeds + project_funded notifications — non-English
-- Companion to 20260805_010_reword_donation_notifications.sql. Same
-- rationale: strip money-adjacent language ("donate", "fund",
-- "sadaqah", "contribution") that led users to think we were asking
-- for real money. Uses UPDATE-in-place (matched on old title) so
-- notification_log foreign keys stay valid.

BEGIN;

-- ── validate_seeds ────────────────────────────────────────────────────
UPDATE public.notification_variants
   SET body = $sb$اپنے Sabiq Seeds کسی Cause میں لگائیں — یتیم، مساجد، مفت کھانے۔ ہر Seed ایک نیکی بوتا ہے ان شاء اللہ۔$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'ur'
   AND title = 'آپ کے Seeds بڑھ رہے ہیں';

UPDATE public.notification_variants
   SET body = $sb$وجه Sabiq Seeds الخاصة بك نحو Cause — أيتام، مساجد، إطعام. كل Seed تزرعها تصبح حسنة إن شاء الله.$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'ar'
   AND title = 'إن Seeds الخاصة بك تنمو';

UPDATE public.notification_variants
   SET body = $sb$Dirigez vos Sabiq Seeds vers une Cause — orphelins, mosquées, repas. Chaque Seed que vous plantez devient une bonne action, in shaa Allah.$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'fr'
   AND title = 'Vos Seeds grandissent';

UPDATE public.notification_variants
   SET body = $sb$Arahkan Sabiq Seeds Anda pada sebuah Cause — yatim, masjid, makanan gratis. Setiap Seed yang Anda tanam menjadi amal, insya Allah.$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'id'
   AND title = 'Seeds Anda bertumbuh';

UPDATE public.notification_variants
   SET body = $sb$Salurkan Sabiq Seeds anda ke satu Cause — anak yatim, masjid, makanan percuma. Setiap Seed yang anda tanam menjadi pahala, insya Allah.$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'ms'
   AND title = 'Seeds anda semakin bertambah';

UPDATE public.notification_variants
   SET body = $sb$Направьте Sabiq Seeds к Cause — сироты, мечети, еда. Каждый Seed, который вы сажаете, становится благим делом, ин ша Аллах.$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'ru'
   AND title = 'Ваши Seeds растут';

UPDATE public.notification_variants
   SET body = $sb$Sabiq Seeds'lerinizi bir Cause'a yönlendirin — yetimler, mescitler, ücretsiz yemekler. Ektiğiniz her Seed bir iyilik olur, in shaa Allah.$sb$
 WHERE notification_type = 'validate_seeds' AND locale = 'tr'
   AND title = $sb$Seeds'leriniz büyüyor$sb$;

-- ── project_funded ────────────────────────────────────────────────────
UPDATE public.notification_variants
   SET title = $sb$آپ کے Seeds کا پھل$sb$,
       body  = $sb$"{projectName}" اپنے ہدف تک پہنچ گیا — حصہ بننے پر جزاك الله خيراً۔ فائدہ اٹھانے والے ہر شخص کے ساتھ آپ کا ثواب جاری ہے۔$sb$
 WHERE notification_type = 'project_funded' AND locale = 'ur'
   AND title = 'آپ کا صدقہ اپنے ہدف تک پہنچ گیا';

UPDATE public.notification_variants
   SET title = $sb$Seeds الخاصة بك أتت ثمرها$sb$,
       body  = $sb$اكتمل "{projectName}" — جزاك الله خيراً على دعمك. أجرك مستمر مع كل من ينتفع به.$sb$
 WHERE notification_type = 'project_funded' AND locale = 'ar'
   AND title = 'صدقتك حققت هدفها';

UPDATE public.notification_variants
   SET title = $sb$Vos Seeds ont porté leurs fruits$sb$,
       body  = $sb$"{projectName}" a atteint son objectif — jazak Allahu khayran pour votre soutien. Votre récompense perdure avec chaque bénéficiaire.$sb$
 WHERE notification_type = 'project_funded' AND locale = 'fr'
   AND title = 'Votre sadaqah a atteint son but';

UPDATE public.notification_variants
   SET title = $sb$Seeds Anda telah berbuah$sb$,
       body  = $sb$"{projectName}" telah mencapai targetnya — jazak Allahu khayran atas dukungan Anda. Pahala Anda terus mengalir.$sb$
 WHERE notification_type = 'project_funded' AND locale = 'id'
   AND title = 'Sadaqah Anda mencapai targetnya';

UPDATE public.notification_variants
   SET title = $sb$Seeds anda telah berbuah$sb$,
       body  = $sb$"{projectName}" telah mencapai sasarannya — jazak Allahu khayran atas sokongan anda. Pahala anda mengalir buat setiap yang dibantu.$sb$
 WHERE notification_type = 'project_funded' AND locale = 'ms'
   AND title = 'Sadaqah anda capai sasaran';

UPDATE public.notification_variants
   SET title = $sb$Ваши Seeds принесли плоды$sb$,
       body  = $sb$Проект «{projectName}» достиг своей цели — джазак Аллаху хайран за вашу поддержку. Награда идет от каждого, кому он принесет пользу.$sb$
 WHERE notification_type = 'project_funded' AND locale = 'ru'
   AND title = 'Ваша садака достигла цели';

UPDATE public.notification_variants
   SET title = $sb$Seeds'leriniz meyve verdi$sb$,
       body  = $sb$"{projectName}" hedefine ulaştı — destek olduğunuz için jazak Allahu khayran. Faydalandığı her canla ödülünüz devam eder.$sb$
 WHERE notification_type = 'project_funded' AND locale = 'tr'
   AND title = 'Sadakanız hedefine ulaştı';

COMMIT;
