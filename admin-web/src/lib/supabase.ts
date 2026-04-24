import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Admin emails — server-side check (matches Flutter app)
export const ADMIN_EMAILS = new Set([
  "pak.zakn@gmail.com",
  "zaid_azam@zeir.io",
]);

// ── Config helpers ──────────────────────────────────────────────────────────

export type AppConfigRow = {
  key: string;
  value: string;
  description?: string;
  updated_at?: string;
  updated_by?: string;
};

export async function fetchAllConfig(): Promise<AppConfigRow[]> {
  const { data, error } = await supabase
    .from("app_config")
    .select("*")
    .order("key");
  if (error) throw error;
  return data ?? [];
}

export async function updateConfigKey(
  key: string,
  value: string,
  adminEmail: string
) {
  const { error } = await supabase
    .from("app_config")
    .upsert(
      {
        key,
        value,
        updated_at: new Date().toISOString(),
        updated_by: adminEmail,
      },
      { onConflict: "key" }
    );
  if (error) throw error;
}
