-- Optional image attachment per variant — Android shows it as a big-picture
-- notification, iOS renders it as a notification attachment. Edge functions
-- include `notification.image` / `android.notification.image` / `apns.fcm_options.image`
-- in the FCM payload when this column is non-null.
--
-- Image URLs must be publicly accessible (Supabase Storage public bucket,
-- CDN, etc.) — FCM cannot present authenticated images.

ALTER TABLE public.notification_variants
  ADD COLUMN IF NOT EXISTS image_url text;

COMMENT ON COLUMN public.notification_variants.image_url IS
  'Optional rich-notification image. Must be publicly accessible (no auth, no signed URLs). Recommended: 1024x512 PNG/JPEG, max ~1MB.';
