// Notification variant resolver.
//
// Picks one active row from `notification_variants` for a given push type,
// preferring the recipient's locale and falling back to English. Then
// substitutes `{name}` placeholders in the title/body strings.
//
// See `supabase/migrations/20260624_020_notification_variants.sql` for the
// schema, RLS, and seed data — and for the list of placeholders each
// notification_type supports.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

export interface ResolvedVariant {
  id: string;
  title: string;
  body: string;
  route: string | null;
  imageUrl: string | null;
}

interface VariantRow {
  id: string;
  title: string;
  body: string;
  route: string | null;
  image_url: string | null;
}

/**
 * Substitute {placeholder} tokens in a template with values from `vars`.
 * Missing keys are left intact so a bad seed never renders as `{undefined}`.
 */
export function fillTemplate(
  template: string,
  vars: Record<string, string | number>,
): string {
  return template.replace(/\{(\w+)\}/g, (match, key) => {
    const v = vars[key];
    return v === undefined || v === null ? match : String(v);
  });
}

/**
 * Picks one random active variant for the given notification_type and
 * locale, then substitutes placeholders. Falls back to English variants
 * if no rows exist for `locale`; falls back to a static {title, body}
 * if even English is missing.
 */
export async function pickVariant(
  supabase: SupabaseClient,
  notificationType: string,
  locale: string,
  vars: Record<string, string | number>,
  staticFallback: { title: string; body: string; route?: string | null },
): Promise<ResolvedVariant> {
  const tryLocale = async (loc: string): Promise<VariantRow | null> => {
    const { data, error } = await supabase
      .from('notification_variants')
      .select('id, title, body, route, image_url')
      .eq('notification_type', notificationType)
      .eq('locale', loc)
      .eq('active', true);
    if (error || !data || data.length === 0) return null;
    return data[Math.floor(Math.random() * data.length)] as VariantRow;
  };

  // Recipient locale first, then English fallback.
  const row = (await tryLocale(locale)) ?? (await tryLocale('en'));

  if (!row) {
    return {
      id: '',
      title: fillTemplate(staticFallback.title, vars),
      body: fillTemplate(staticFallback.body, vars),
      route: staticFallback.route ?? null,
      imageUrl: null,
    };
  }

  return {
    id: row.id,
    title: fillTemplate(row.title, vars),
    body: fillTemplate(row.body, vars),
    route: row.route,
    imageUrl: row.image_url,
  };
}
