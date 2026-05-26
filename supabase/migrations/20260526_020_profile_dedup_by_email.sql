-- =============================================================================
-- 20260526_020_profile_dedup_by_email
--
-- Architectural bugfix: users who signed in through different auth methods
-- (Google OAuth, email/password, Quran Foundation custom OAuth) for the
-- same real-world email ended up with a separate `profiles` row per
-- method, polluting the leaderboard, donation totals, etc.
--
-- Direction-of-merge decision: we ALWAYS merge older duplicate(s) INTO
-- the row owned by the currently authenticated user (auth.uid()). This
-- keeps the user's active session pointing at a profile row that
-- actually contains their data — if we did it the other way around the
-- session's profile row would be empty and every RPC that requires
-- `auth.uid() = p_user_id` would see zero.
--
-- This migration:
--   1) Adds a `merged_into_id` column so merged rows can be hidden from
--      user-facing queries without losing audit history.
--   2) Ships an internal `_merge_profile_into(src, dst)` helper that
--      walks every user-keyed FK table, moves rows, merges aggregate
--      counts and marks src as merged.
--   3) Ships one-shot `consolidate_duplicate_profiles_by_email()` for
--      cleaning up the existing mess. Run from the SQL Editor once.
--   4) Ships `dedupe_profile_on_login()` — SECURITY DEFINER RPC the
--      Flutter app calls after every successful login. If an OLDER
--      profile exists for the caller's email, it's merged INTO the
--      caller and tagged as merged. Returns the caller's id (the
--      canonical row from the user's perspective from now on).
--   5) Rewrites `link_qf_profile` to use the same internal helper.
--   6) Adds a `leaderboard_global_v2` view that excludes merged rows
--      (drop-in replacement if your existing `leaderboard_global` view
--      doesn't filter).
--
-- Idempotent — safe to re-run.
-- =============================================================================

-- ── 1. Schema ──────────────────────────────────────────────────────────────
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS merged_into_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_merged_into
  ON profiles(merged_into_id) WHERE merged_into_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_email_active
  ON profiles(lower(trim(email)))
  WHERE merged_into_id IS NULL AND email IS NOT NULL;


-- ── 2. Internal helper: merge src → dst (does NOT decide which is which) ──
CREATE OR REPLACE FUNCTION public._merge_profile_into(
  p_src UUID,
  p_dst UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_src profiles%ROWTYPE;
  v_dst profiles%ROWTYPE;
BEGIN
  IF p_src = p_dst OR p_src IS NULL OR p_dst IS NULL THEN RETURN; END IF;

  SELECT * INTO v_src FROM profiles WHERE id = p_src FOR UPDATE;
  SELECT * INTO v_dst FROM profiles WHERE id = p_dst FOR UPDATE;
  IF v_src.id IS NULL OR v_dst.id IS NULL THEN RETURN; END IF;
  -- Refuse to merge if src is already merged into something else
  IF v_src.merged_into_id IS NOT NULL THEN RETURN; END IF;

  -- ── 2a. Move FK rows from src → dst, handling per-table uniqueness ──
  -- user_donations: no per-row unique on user_id, simple update
  UPDATE user_donations SET user_id = p_dst WHERE user_id = p_src;

  -- user_activities
  BEGIN
    UPDATE user_activities SET user_id = p_dst WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- streak_history: UNIQUE (user_id, streak_type, activity_date) — drop
  -- src rows that already exist for dst on the same (type, date), then
  -- move the remainder. Dst's row wins on conflict (it's the live one).
  BEGIN
    DELETE FROM streak_history
     WHERE user_id = p_src
       AND (streak_type, activity_date) IN (
         SELECT streak_type, activity_date
         FROM streak_history
         WHERE user_id = p_dst
       );
    UPDATE streak_history SET user_id = p_dst WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- user_badges: UNIQUE (user_id, badge_id) — keep dst's if conflict
  BEGIN
    DELETE FROM user_badges
     WHERE user_id = p_src
       AND badge_id IN (SELECT badge_id FROM user_badges WHERE user_id = p_dst);
    UPDATE user_badges SET user_id = p_dst WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- user_monthly_stats: UNIQUE (user_id, month) — SUM into dst then drop src
  BEGIN
    INSERT INTO user_monthly_stats AS d (
      user_id, month,
      ayahs_read, quran_sessions, quran_time_sec,
      dhikr_sets, dhikr_count, dhikr_time_sec,
      total_points, login_days, active_days
    )
    SELECT
      p_dst, s.month,
      s.ayahs_read, s.quran_sessions, s.quran_time_sec,
      s.dhikr_sets, s.dhikr_count, s.dhikr_time_sec,
      s.total_points, s.login_days, s.active_days
    FROM user_monthly_stats s
    WHERE s.user_id = p_src
    ON CONFLICT (user_id, month) DO UPDATE SET
      ayahs_read     = d.ayahs_read     + EXCLUDED.ayahs_read,
      quran_sessions = d.quran_sessions + EXCLUDED.quran_sessions,
      quran_time_sec = d.quran_time_sec + EXCLUDED.quran_time_sec,
      dhikr_sets     = d.dhikr_sets     + EXCLUDED.dhikr_sets,
      dhikr_count    = d.dhikr_count    + EXCLUDED.dhikr_count,
      dhikr_time_sec = d.dhikr_time_sec + EXCLUDED.dhikr_time_sec,
      total_points   = d.total_points   + EXCLUDED.total_points,
      login_days     = d.login_days     + EXCLUDED.login_days,
      active_days    = d.active_days    + EXCLUDED.active_days,
      updated_at     = now();
    DELETE FROM user_monthly_stats WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- user_daily_stats: UNIQUE (user_id, stat_date)
  BEGIN
    INSERT INTO user_daily_stats AS d (
      user_id, stat_date,
      ayahs_read, dhikr_count,
      quran_time_sec, dhikr_time_sec
    )
    SELECT
      p_dst, s.stat_date,
      s.ayahs_read, s.dhikr_count,
      s.quran_time_sec, s.dhikr_time_sec
    FROM user_daily_stats s
    WHERE s.user_id = p_src
    ON CONFLICT (user_id, stat_date) DO UPDATE SET
      ayahs_read     = d.ayahs_read     + EXCLUDED.ayahs_read,
      dhikr_count    = d.dhikr_count    + EXCLUDED.dhikr_count,
      quran_time_sec = d.quran_time_sec + EXCLUDED.quran_time_sec,
      dhikr_time_sec = d.dhikr_time_sec + EXCLUDED.dhikr_time_sec,
      updated_at     = now();
    DELETE FROM user_daily_stats WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- user_dhikr_phrase_counts: UNIQUE (user_id, phrase_id)
  BEGIN
    INSERT INTO user_dhikr_phrase_counts AS d (user_id, phrase_id, count)
    SELECT p_dst, s.phrase_id, s.count
    FROM user_dhikr_phrase_counts s
    WHERE s.user_id = p_src
    ON CONFLICT (user_id, phrase_id) DO UPDATE SET
      count      = d.count + EXCLUDED.count,
      updated_at = now();
    DELETE FROM user_dhikr_phrase_counts WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- user_analytics: presumably 1 row per user
  BEGIN
    UPDATE user_analytics
       SET quran_time_sec = COALESCE(quran_time_sec, 0)
                          + COALESCE((SELECT quran_time_sec FROM user_analytics WHERE user_id = p_src), 0),
           dhikr_time_sec = COALESCE(dhikr_time_sec, 0)
                          + COALESCE((SELECT dhikr_time_sec FROM user_analytics WHERE user_id = p_src), 0)
     WHERE user_id = p_dst;
    DELETE FROM user_analytics WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- user_challenge_progress
  BEGIN
    DELETE FROM user_challenge_progress
     WHERE user_id = p_src
       AND challenge_id IN (
         SELECT challenge_id FROM user_challenge_progress WHERE user_id = p_dst
       );
    UPDATE user_challenge_progress SET user_id = p_dst WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- quran bookmarks/favorites: keep dst's, drop src's
  BEGIN DELETE FROM quran_bookmarks WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;
  BEGIN DELETE FROM quran_favorites WHERE user_id = p_src;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- ── 2b. Absorb src's aggregate counters INTO dst ──
  UPDATE profiles
  SET
    -- Cumulative totals: SUM
    noor_points        = COALESCE(noor_points, 0) + COALESCE(v_src.noor_points, 0),
    total_xp           = COALESCE(total_xp, 0) + COALESCE(v_src.total_xp, 0),
    ayahs_read         = COALESCE(ayahs_read, 0) + COALESCE(v_src.ayahs_read, 0),
    dhikr_count        = COALESCE(dhikr_count, 0) + COALESCE(v_src.dhikr_count, 0),
    -- Streaks: MAX
    day_streak         = GREATEST(COALESCE(day_streak, 0), COALESCE(v_src.day_streak, 0)),
    login_streak       = GREATEST(COALESCE(login_streak, 0), COALESCE(v_src.login_streak, 0)),
    dhikr_streak       = GREATEST(COALESCE(dhikr_streak, 0), COALESCE(v_src.dhikr_streak, 0)),
    quran_streak       = GREATEST(COALESCE(quran_streak, 0), COALESCE(v_src.quran_streak, 0)),
    best_login_streak  = GREATEST(COALESCE(best_login_streak, 0), COALESCE(v_src.best_login_streak, 0)),
    best_dhikr_streak  = GREATEST(COALESCE(best_dhikr_streak, 0), COALESCE(v_src.best_dhikr_streak, 0)),
    best_quran_streak  = GREATEST(COALESCE(best_quran_streak, 0), COALESCE(v_src.best_quran_streak, 0)),
    -- Boolean: OR
    setup_done         = COALESCE(setup_done, false) OR COALESCE(v_src.setup_done, false),
    -- Backfill blanks from src
    country            = COALESCE(NULLIF(trim(country), ''), v_src.country),
    city               = COALESCE(NULLIF(trim(city), ''), v_src.city),
    mosque_team        = COALESCE(NULLIF(trim(mosque_team), ''), v_src.mosque_team),
    avatar_url         = COALESCE(NULLIF(trim(avatar_url), ''), v_src.avatar_url),
    display_name       = COALESCE(NULLIF(trim(display_name), ''), v_src.display_name),
    level              = GREATEST(COALESCE(level, 1), COALESCE(v_src.level, 1)),
    updated_at         = now()
  WHERE id = p_dst;

  -- Recompute level from new total_xp (best-effort)
  BEGIN
    UPDATE profiles SET level = (
      SELECT COALESCE(MAX(xl.level), 1)
      FROM xp_levels xl
      WHERE xl.xp_required <= profiles.total_xp
    )
    WHERE id = p_dst;
  EXCEPTION WHEN undefined_table THEN NULL; END;

  -- ── 2c. Mark src as merged so it's invisible to user-facing queries ──
  UPDATE profiles
  SET merged_into_id = p_dst,
      email = CASE
        WHEN email IS NULL OR email = '' THEN email
        WHEN email LIKE '%\_merged\_%' ESCAPE '\' THEN email
        ELSE email || '_merged_' || p_src::text
      END,
      updated_at = now()
  WHERE id = p_src;
END $$;


-- ── 3. Per-login dedup — merges any OLDER profile with the caller's email
--      INTO the caller's row. Returns the caller's id (now canonical). ──
CREATE OR REPLACE FUNCTION public.dedupe_profile_on_login(p_email TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_me   UUID := auth.uid();
  v_norm TEXT := lower(trim(p_email));
  v_dup  UUID;
BEGIN
  IF v_me IS NULL OR v_norm IS NULL OR v_norm = '' THEN
    RETURN v_me;
  END IF;

  -- Make sure my profile row exists with this email. Don't blow up if
  -- the unique-ish index trips — we'll resolve it via the merge below.
  BEGIN
    INSERT INTO profiles (id, email, setup_done)
    VALUES (v_me, p_email, false)
    ON CONFLICT (id) DO UPDATE
      SET email = COALESCE(NULLIF(EXCLUDED.email, ''), profiles.email),
          updated_at = now();
  EXCEPTION WHEN OTHERS THEN NULL; END;

  -- Find any OTHER active profile with this email.
  -- If multiple exist (legacy data), pick the one with the most history.
  SELECT id INTO v_dup
  FROM profiles
  WHERE id <> v_me
    AND lower(trim(email)) = v_norm
    AND merged_into_id IS NULL
    AND email NOT LIKE '%\_merged\_%' ESCAPE '\'
  ORDER BY total_xp DESC NULLS LAST, created_at ASC
  LIMIT 1;

  IF v_dup IS NULL THEN
    RETURN v_me;
  END IF;

  -- Merge the duplicate INTO me (caller). My session stays valid.
  PERFORM public._merge_profile_into(v_dup, v_me);
  RETURN v_me;
END $$;

REVOKE ALL ON FUNCTION public.dedupe_profile_on_login(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dedupe_profile_on_login(text) TO authenticated;


-- ── 4. One-time backfill — runs through ALL existing duplicate groups ─────
CREATE OR REPLACE FUNCTION public.consolidate_duplicate_profiles_by_email()
RETURNS TABLE (
  norm_email        TEXT,
  canonical_id      UUID,
  duplicate_ids     UUID[],
  duplicates_merged INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  r RECORD;
  v_canonical UUID;
  v_dups UUID[];
  v_dup UUID;
BEGIN
  FOR r IN (
    SELECT
      lower(trim(email)) AS ne,
      -- Canonical = oldest, tie-break by highest XP. Backfill is a one-time
      -- cleanup so we don't have the "current session" constraint here.
      array_agg(id ORDER BY created_at ASC, total_xp DESC NULLS LAST) AS ids
    FROM profiles
    WHERE email IS NOT NULL
      AND trim(email) <> ''
      AND email NOT LIKE '%\_merged\_%' ESCAPE '\'
      AND merged_into_id IS NULL
    GROUP BY lower(trim(email))
    HAVING COUNT(*) > 1
  ) LOOP
    v_canonical := r.ids[1];
    v_dups      := r.ids[2:];

    FOREACH v_dup IN ARRAY v_dups LOOP
      PERFORM public._merge_profile_into(v_dup, v_canonical);
    END LOOP;

    norm_email        := r.ne;
    canonical_id      := v_canonical;
    duplicate_ids     := v_dups;
    duplicates_merged := array_length(v_dups, 1);
    RETURN NEXT;
  END LOOP;
END $$;

REVOKE ALL ON FUNCTION public.consolidate_duplicate_profiles_by_email() FROM PUBLIC;
-- Intentionally NOT granted. Run from SQL Editor only.


-- ── 5. Rewrite link_qf_profile to use the shared merge helper ──────────────
CREATE OR REPLACE FUNCTION public.link_qf_profile(
    p_email   text,
    p_new_id  uuid,
    p_name    text,
    p_picture text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_jwt_email TEXT;
    v_dup       UUID;
BEGIN
    IF auth.uid() IS NULL OR auth.uid() <> p_new_id THEN
        RETURN 'ERROR: forbidden';
    END IF;

    v_jwt_email := lower(coalesce(auth.jwt() ->> 'email', ''));
    IF v_jwt_email = '' OR v_jwt_email <> lower(p_email) THEN
        RETURN 'ERROR: email mismatch';
    END IF;

    -- Make sure the caller's profile row exists with the right metadata.
    INSERT INTO profiles (id, email, display_name, avatar_url, setup_done)
    VALUES (p_new_id, p_email, p_name, p_picture, true)
    ON CONFLICT (id) DO UPDATE SET
        email        = COALESCE(EXCLUDED.email, profiles.email),
        display_name = COALESCE(NULLIF(trim(EXCLUDED.display_name), ''), profiles.display_name),
        avatar_url   = COALESCE(NULLIF(trim(EXCLUDED.avatar_url), ''), profiles.avatar_url),
        setup_done   = profiles.setup_done OR EXCLUDED.setup_done,
        updated_at   = now();

    -- Find another active profile with this email and merge it INTO me.
    SELECT id INTO v_dup
    FROM profiles
    WHERE id <> p_new_id
      AND lower(trim(email)) = lower(trim(p_email))
      AND merged_into_id IS NULL
      AND email NOT LIKE '%\_merged\_%' ESCAPE '\'
    ORDER BY total_xp DESC NULLS LAST, created_at ASC
    LIMIT 1;

    IF v_dup IS NULL THEN
        RETURN 'SUCCESS: no prior profile to merge';
    END IF;

    PERFORM public._merge_profile_into(v_dup, p_new_id);
    RETURN 'SUCCESS: merged ' || v_dup::text;
END $$;

REVOKE ALL ON FUNCTION public.link_qf_profile(text, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.link_qf_profile(text, uuid, text, text) TO authenticated;


-- ── 6. Drop-in leaderboard view that excludes merged rows ──────────────────
-- The existing `leaderboard_global` view may include merged rows. We
-- create `leaderboard_global_v2` so the Flutter side can switch to it
-- without our migration tripping if the old view has a custom shape.
-- After verifying, you can swap the old view to point at this one.
CREATE OR REPLACE VIEW public.leaderboard_global_v2 AS
  SELECT
    id,
    display_name,
    avatar_url,
    avatar_color,
    country,
    city,
    total_xp,
    noor_points,
    level,
    day_streak,
    best_login_streak,
    best_dhikr_streak,
    best_quran_streak,
    ayahs_read,
    dhikr_count
  FROM profiles
  WHERE merged_into_id IS NULL
    AND COALESCE(setup_done, false) = true
  ORDER BY total_xp DESC NULLS LAST, created_at ASC;

GRANT SELECT ON public.leaderboard_global_v2 TO authenticated, anon;


-- ── 7. Verify ──────────────────────────────────────────────────────────────
SELECT 'merged_into_id column' AS object,
       (SELECT count(*) FROM information_schema.columns
         WHERE table_name = 'profiles' AND column_name = 'merged_into_id') AS exists;
SELECT routine_name, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('_merge_profile_into',
                       'consolidate_duplicate_profiles_by_email',
                       'dedupe_profile_on_login',
                       'link_qf_profile')
ORDER BY routine_name;

-- Dry-run report of duplicates the backfill would catch (no changes yet)
SELECT
  lower(trim(email)) AS norm_email,
  count(*)           AS row_count,
  array_agg(id ORDER BY created_at)::text[] AS profile_ids
FROM profiles
WHERE email IS NOT NULL
  AND trim(email) <> ''
  AND email NOT LIKE '%\_merged\_%' ESCAPE '\'
  AND merged_into_id IS NULL
GROUP BY lower(trim(email))
HAVING count(*) > 1
ORDER BY count(*) DESC;
