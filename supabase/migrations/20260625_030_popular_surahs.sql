-- ─────────────────────────────────────────────────────────────────────────────
-- 20260625_030_popular_surahs.sql
--
-- "Frequently read by Community" — top surahs by ayah reads in the last
-- 7 days. Drives the right column of the Quran engagement strip.
--
-- Source: user_activities rows where activity_type = 'quran' carry the
-- surah number in metadata->>'surah' (see earn_ayah_points RPC).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW public.popular_surahs_7d AS
  SELECT
    (metadata->>'surah')::int       AS surah,
    COUNT(*)::int                   AS read_count
  FROM user_activities
  WHERE activity_type = 'quran'
    AND created_at >= now() - interval '7 days'
    AND metadata ? 'surah'
  GROUP BY (metadata->>'surah')::int
  ORDER BY read_count DESC
  LIMIT 10;

ALTER VIEW public.popular_surahs_7d SET (security_invoker = true);
GRANT SELECT ON public.popular_surahs_7d TO authenticated, anon;
