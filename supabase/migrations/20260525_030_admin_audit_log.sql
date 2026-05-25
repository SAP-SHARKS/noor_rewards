-- =============================================================================
-- 20260525_030_admin_audit_log
--
-- Fixes audit-final.md F-26: admin mutations leave no audit trail.
-- Creates an append-only log + triggers on the four admin-managed tables.
-- Only admins can read; nobody can update or delete rows (immutable).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES auth.users(id),
  action        TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  target_table  TEXT NOT NULL,
  target_id     TEXT,
  before_data   JSONB,
  after_data    JSONB,
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_table_time
  ON public.admin_audit_log(target_table, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_actor
  ON public.admin_audit_log(actor_user_id, occurred_at DESC);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Admins read everything; no client may write/update/delete (writes go
-- through the trigger, which runs as the table owner and bypasses RLS).
DROP POLICY IF EXISTS "admin_audit_admin_read" ON public.admin_audit_log;
CREATE POLICY "admin_audit_admin_read" ON public.admin_audit_log
  FOR SELECT TO authenticated USING (public.is_admin());

-- Trigger function: writes one row per change.
CREATE OR REPLACE FUNCTION public._admin_audit_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_target_id TEXT;
BEGIN
  v_target_id := COALESCE(
    (CASE WHEN TG_OP = 'DELETE' THEN OLD.id::TEXT
          ELSE NEW.id::TEXT END),
    ''
  );

  INSERT INTO public.admin_audit_log
    (actor_user_id, action, target_table, target_id, before_data, after_data)
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    v_target_id,
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );

  RETURN COALESCE(NEW, OLD);
END $$;

-- Attach to the four admin-managed tables.
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'app_config',
    'sponsored_orphans',
    'community_project_media',
    'onboarding_images'
  ] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS audit_%I ON public.%I', t, t);
    EXECUTE format(
      'CREATE TRIGGER audit_%I AFTER INSERT OR UPDATE OR DELETE ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public._admin_audit_trigger()',
      t, t
    );
  END LOOP;
END $$;

-- Verify
SELECT 'admin_audit_log table' AS object,
       (SELECT count(*) FROM information_schema.tables
        WHERE table_name='admin_audit_log') AS exists;
SELECT event_object_table, trigger_name
FROM information_schema.triggers
WHERE trigger_name LIKE 'audit_%'
ORDER BY event_object_table;
