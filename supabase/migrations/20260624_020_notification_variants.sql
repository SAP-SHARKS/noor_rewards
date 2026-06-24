-- Dynamic notification wording.
--
-- Replaces the hardcoded title/body strings inside each push Edge Function
-- with a randomly-picked row from `notification_variants`. Admins add or
-- edit variants without redeploying functions, and (once translations are
-- backfilled) each user receives the variant in their own locale.
--
-- Template placeholders: `{name}` tokens inside title/body are substituted
-- at send time by the Edge Function — see `supabase/functions/_shared/
-- variants.ts`. Each notification_type supports a fixed set of placeholders:
--
--   streak_at_risk      → {streak}, {type}
--   nightly_checkin     → {seeds}
--   community_momentum  → {count}
--   resume_reading      → {surahName}, {ayah}
--   morning_azkaar      → (none)
--   evening_azkaar      → (none)
--   level_up            → {ptsNeeded}, {nextLevel}, {nextTitle}
--   monthly_quran       → {monthName}
--   monthly_milestone   → {monthName}, {ayahs}
--
-- Anything not listed is left as-is in the rendered string.

CREATE TABLE IF NOT EXISTS public.notification_variants (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_type text        NOT NULL,
  locale          text          NOT NULL DEFAULT 'en',
  title           text          NOT NULL,
  body            text          NOT NULL,
  route           text,
  active          boolean       NOT NULL DEFAULT true,
  created_at      timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notif_variants_pick
  ON public.notification_variants (notification_type, locale, active);

ALTER TABLE public.notification_variants ENABLE ROW LEVEL SECURITY;

-- Authenticated users can READ (admin panel lists them; client never sends).
DROP POLICY IF EXISTS notif_variants_read ON public.notification_variants;
CREATE POLICY notif_variants_read
  ON public.notification_variants
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can mutate.
DROP POLICY IF EXISTS notif_variants_write ON public.notification_variants;
CREATE POLICY notif_variants_write
  ON public.notification_variants
  FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM public.app_roles WHERE user_id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.app_roles WHERE user_id = auth.uid() AND role = 'admin'));

-- ─── Track which variant was sent on each push ────────────────────────────
ALTER TABLE public.notification_log
  ADD COLUMN IF NOT EXISTS variant_id uuid REFERENCES public.notification_variants(id);

CREATE INDEX IF NOT EXISTS idx_notif_log_variant
  ON public.notification_log (variant_id);

-- ─── Optional: per-user locale for matching variant rows ─────────────────
-- App should write the active app locale here on token refresh (Dart side
-- update lives in notification_service.dart's _saveTokenWithLocation).
-- Default 'en' so existing 22 rows keep working until the app pushes
-- their actual locale.
ALTER TABLE public.fcm_tokens
  ADD COLUMN IF NOT EXISTS app_locale text NOT NULL DEFAULT 'en';

-- ─── Seed: English variants ──────────────────────────────────────────────
-- 4-6 variants per type. Random pick avoids users seeing the same line
-- repeatedly. Translators add other locales by inserting rows with the
-- same notification_type and a different locale.
INSERT INTO public.notification_variants (notification_type, locale, title, body, route) VALUES
-- streak_at_risk
('streak_at_risk', 'en', 'Keep the chain alive 🔥', 'Your {type} streak hit {streak} days. One more tap before midnight locks it in.', 'quran'),
('streak_at_risk', 'en', '{streak} days strong — don''t stop now', 'You''ve come too far to break your {type} streak. Open Sabiq and seal today.', 'quran'),
('streak_at_risk', 'en', 'Tonight matters', 'Skip today and {streak} days of {type} resets to zero. Two minutes saves it.', 'quran'),
('streak_at_risk', 'en', 'Your streak is at risk', '{streak} days of {type} are on the line. Open Sabiq before the clock turns.', 'quran'),
('streak_at_risk', 'en', 'One tap, streak saved', 'Lock in day {streak} of your {type} streak — even one ayah counts.', 'quran'),

-- nightly_checkin
('nightly_checkin', 'en', 'Seal the day 🌙', 'Tap to validate today''s Seeds before they expire at midnight.', 'home'),
('nightly_checkin', 'en', 'Don''t leave Seeds on the table', 'Your unclaimed Seeds reset at midnight. Validate now to keep them.', 'home'),
('nightly_checkin', 'en', 'End your day with barakah', 'A few moments of remembrance now — and seal today''s reward.', 'home'),
('nightly_checkin', 'en', 'Time to wrap today', 'Validate your day and lock in your Sabiq Seeds before midnight.', 'home'),
('nightly_checkin', 'en', 'Almost midnight', 'Seal today''s journey — your Seeds are waiting to be validated.', 'home'),

-- community_momentum
('community_momentum', 'en', 'The Ummah is reading 📖', '{count} believers are reading the Quran right now. Join them.', 'quran'),
('community_momentum', 'en', 'Join the morning recitation', '{count} people opened the Quran today. Make it {count}+1.', 'quran'),
('community_momentum', 'en', 'Don''t read alone', '{count} brothers and sisters are with you in the Quran today. Open and join.', 'quran'),
('community_momentum', 'en', 'The community is here', '{count} believers reciting right now. Yours could be the next ayah.', 'quran'),
('community_momentum', 'en', 'Be part of today''s reading', '{count} people are reading the Quran. Take 2 minutes and join them.', 'quran'),

-- resume_reading
('resume_reading', 'en', 'Pick up where you left off', 'You stopped at {surahName} {ayah}. The next ayah is one tap away.', 'quran'),
('resume_reading', 'en', 'Continue {surahName}', 'You were on ayah {ayah}. Open and finish what you started.', 'quran'),
('resume_reading', 'en', '{surahName} is waiting', 'You paused at ayah {ayah}. A few minutes is all it takes to continue.', 'quran'),
('resume_reading', 'en', 'One more ayah?', 'You left {surahName} at {ayah}. Let''s read one more today.', 'quran'),
('resume_reading', 'en', 'Your bookmark in {surahName}', 'Ayah {ayah} is saved for you. Open Sabiq to keep going.', 'quran'),

-- morning_azkaar
('morning_azkaar', 'en', 'Begin the day with adhkar ☀️', 'A few minutes of morning remembrance protects your whole day.', 'morning'),
('morning_azkaar', 'en', 'Start strong', 'The morning adhkar is the believer''s shield. Don''t leave home without them.', 'morning'),
('morning_azkaar', 'en', 'Open the day with dhikr', 'Take 5 minutes for morning adhkar — your day will thank you.', 'morning'),
('morning_azkaar', 'en', 'Subhan Allah, good morning 🌅', 'The morning adhkar is waiting. Two minutes and you''re covered.', 'morning'),
('morning_azkaar', 'en', 'Your morning shield', 'Set the tone for today — start with the morning adhkar.', 'morning'),

-- evening_azkaar
('evening_azkaar', 'en', 'Wind down with adhkar 🌙', 'Close today with the evening remembrance and earn its barakah.', 'evening'),
('evening_azkaar', 'en', 'Time for the evening dhikr', 'A few moments of remembrance now seals the day in noor.', 'evening'),
('evening_azkaar', 'en', 'Evening adhkar awaits', 'Take 5 minutes to recite the evening adhkar before sleep.', 'evening'),
('evening_azkaar', 'en', 'Close the day right', 'The Prophet ﷺ never missed his evening adhkar. Join the sunnah.', 'evening'),
('evening_azkaar', 'en', 'One more habit before bed', 'Recite the evening adhkar and rest under Allah''s protection.', 'evening'),

-- level_up
('level_up', 'en', '🚀 You''re close to Level {nextLevel}', 'Just {ptsNeeded} more Seeds and you become a {nextTitle}.', 'profile'),
('level_up', 'en', '{nextTitle} status is right there', 'Only {ptsNeeded} Seeds away from Level {nextLevel}. Don''t stop now.', 'profile'),
('level_up', 'en', 'One push, one new title', 'Earn {ptsNeeded} Seeds today and you unlock {nextTitle}.', 'profile'),
('level_up', 'en', 'Almost there 🏆', '{ptsNeeded} Seeds between you and Level {nextLevel} ({nextTitle}). Let''s go.', 'profile'),

-- monthly_quran
('monthly_quran', 'en', 'A fresh month, a fresh page 📖', '{monthName} is here. Set a Quran goal for this month — even one ayah a day counts.', 'quran'),
('monthly_quran', 'en', 'New month, new niyyah', 'Start {monthName} strong. Open the Quran today and write your intention.', 'quran'),
('monthly_quran', 'en', 'Make {monthName} the month', 'The best deeds are the consistent ones. Start your Quran rhythm today.', 'quran'),
('monthly_quran', 'en', 'Reset for {monthName}', 'A new month is mercy. Let your first act be opening the Quran.', 'quran'),

-- monthly_milestone
('monthly_milestone', 'en', 'Look back at {monthName} 🌙', 'You read {ayahs} ayahs last month, masha''Allah. See your full impact.', 'akhirah'),
('monthly_milestone', 'en', '{ayahs} ayahs last month, alhamdulillah', 'See how your {monthName} compares to your past months.', 'akhirah'),
('monthly_milestone', 'en', 'Your {monthName} in numbers', '{ayahs} ayahs. Real lives helped. Open Sabiq to see the full picture.', 'akhirah'),
('monthly_milestone', 'en', 'A month of barakah', 'You earned hasanat for {ayahs} ayahs in {monthName}. View your akhirah balance.', 'akhirah');
