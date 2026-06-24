-- Storage bucket for push notification image attachments.
--
-- Admins upload optional images when creating/editing notification_variants
-- rows; the resulting public URL is saved to `notification_variants.image_url`
-- and forwarded to FCM as the rich-notification image.
--
-- Bucket is public-read so FCM/APNs can fetch the URL without auth, and
-- only admins (rows in public.app_roles with role='admin') can write.

INSERT INTO storage.buckets (id, name, public)
VALUES ('notifications', 'notifications', true)
ON CONFLICT (id) DO NOTHING;

-- Public read
DROP POLICY IF EXISTS "notifications public read" ON storage.objects;
CREATE POLICY "notifications public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'notifications');

-- Admin write (insert + update + delete)
DROP POLICY IF EXISTS "notifications admin write" ON storage.objects;
CREATE POLICY "notifications admin write"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'notifications'
    AND EXISTS (
      SELECT 1 FROM public.app_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    bucket_id = 'notifications'
    AND EXISTS (
      SELECT 1 FROM public.app_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
