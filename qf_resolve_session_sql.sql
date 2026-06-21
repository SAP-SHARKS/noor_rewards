-- ════════════════════════════════════════════════════════════════════
-- qf-resolve-session helpers
--
-- Two SECURITY DEFINER lookup functions the edge function calls via RPC
-- to resolve an incoming QF identity (sub + email) to an existing
-- auth.users.id without needing direct table access.
-- ════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.find_auth_user_by_qf_sub(p_sub TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id UUID;
BEGIN
  IF p_sub IS NULL OR length(trim(p_sub)) = 0 THEN
    RETURN NULL;
  END IF;
  SELECT u.id
  INTO v_id
  FROM auth.users u
  WHERE u.raw_user_meta_data->>'qf_sub' = p_sub
    AND u.deleted_at IS NULL
  ORDER BY u.created_at ASC
  LIMIT 1;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.find_auth_user_by_email(p_email TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id UUID;
BEGIN
  IF p_email IS NULL OR length(trim(p_email)) = 0 THEN
    RETURN NULL;
  END IF;
  SELECT u.id
  INTO v_id
  FROM auth.users u
  WHERE LOWER(u.email) = LOWER(trim(p_email))
    AND u.deleted_at IS NULL
  ORDER BY u.created_at ASC
  LIMIT 1;
  RETURN v_id;
END;
$$;

-- Only the service role (used by the edge function) needs to call these.
REVOKE EXECUTE ON FUNCTION public.find_auth_user_by_qf_sub(TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.find_auth_user_by_email(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.find_auth_user_by_qf_sub(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.find_auth_user_by_email(TEXT) TO service_role;
