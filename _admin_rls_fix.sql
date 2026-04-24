-- Fix RLS policies for app_config table so authenticated admin users can read/write
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- 1. Allow all authenticated users to read app_config
DROP POLICY IF EXISTS "config_select_auth" ON app_config;
CREATE POLICY "config_select_auth" ON app_config
  FOR SELECT USING (true);

-- 2. Allow authenticated users to insert new config keys
DROP POLICY IF EXISTS "config_insert_auth" ON app_config;
CREATE POLICY "config_insert_auth" ON app_config
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 3. Allow authenticated users to update config values
DROP POLICY IF EXISTS "config_update_auth" ON app_config;
CREATE POLICY "config_update_auth" ON app_config
  FOR UPDATE USING (auth.role() = 'authenticated');

-- 4. Allow authenticated users to delete config keys
DROP POLICY IF EXISTS "config_delete_auth" ON app_config;
CREATE POLICY "config_delete_auth" ON app_config
  FOR DELETE USING (auth.role() = 'authenticated');

-- Verify RLS is enabled
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Verify policies
SELECT * FROM pg_policies WHERE tablename = 'app_config';
