-- This RPC links a NEW anonymous Supabase user to an OLD QF profile
-- by migrating their points, streaks, and progress, then deleting the old duplicate.

DROP FUNCTION IF EXISTS link_qf_profile(text, uuid, text, text);

CREATE OR REPLACE FUNCTION link_qf_profile(
    p_email text,
    p_new_id uuid,
    p_name text,
    p_picture text
) RETURNS text AS $$
DECLARE
    v_old_profile RECORD;
BEGIN
    SELECT * INTO v_old_profile
    FROM profiles
    WHERE email = p_email AND id != p_new_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN 'ERROR: No old profile found for email ' || p_email;
    END IF;

    BEGIN
        INSERT INTO profiles (id, email, display_name, avatar_url, setup_done)
        VALUES (p_new_id, p_email, p_name, p_picture, true)
        ON CONFLICT (id) DO NOTHING;

        -- To avoid UNIQUE constraint violations during the transfer (like referral_code),
        -- we must clear the unique fields from the old row BEFORE we update the new row.
        UPDATE profiles 
        SET referral_code = NULL, email = email || '_merged_' || (gen_random_uuid())::text 
        WHERE id = v_old_profile.id;

        UPDATE profiles
        SET
            display_name = COALESCE(v_old_profile.display_name, profiles.display_name, p_name),
            country = v_old_profile.country,
            goals = v_old_profile.goals,
            noor_points = v_old_profile.noor_points,
            day_streak = v_old_profile.day_streak,
            level = v_old_profile.level,
            setup_done = true,
            ayahs_read = v_old_profile.ayahs_read,
            dhikr_count = v_old_profile.dhikr_count,
            total_xp = v_old_profile.total_xp,
            city = v_old_profile.city,
            mosque_team = v_old_profile.mosque_team,
            avatar_color = v_old_profile.avatar_color,
            referral_code = v_old_profile.referral_code,
            referred_by = v_old_profile.referred_by,
            login_streak = v_old_profile.login_streak,
            dhikr_streak = v_old_profile.dhikr_streak,
            quran_streak = v_old_profile.quran_streak,
            login_streak_updated_at = v_old_profile.login_streak_updated_at,
            dhikr_streak_updated_at = v_old_profile.dhikr_streak_updated_at,
            quran_streak_updated_at = v_old_profile.quran_streak_updated_at,
            best_login_streak = v_old_profile.best_login_streak,
            best_dhikr_streak = v_old_profile.best_dhikr_streak,
            best_quran_streak = v_old_profile.best_quran_streak
        WHERE id = p_new_id;
        
        -- We intentionally DO NOT DELETE the old duplicate profile to prevent any
        -- foreign-key constraint violations on child tables (like history logs).
        -- Since we removed its email and referral code, it is completely safely deactivated.
    EXCEPTION WHEN OTHERS THEN
        RETURN 'ERROR internal: ' || SQLERRM;
    END;

    RETURN 'SUCCESS';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
