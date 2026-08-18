-- =============================================================================
-- 20260818_010_azkar_salawat_short_benefit_backfill
--
-- Fills the missing short_benefit fields for the two salawat rows so the
-- list-view second-line tagline renders:
--
--   • evening_32 — English base was never populated (only ur/ar/fr/id/ms/ru/tr
--     were seeded in 20260706_010 + 20260706_020). English-locale users saw
--     no tagline under this item.
--   • morning_33 — brand-new row inserted in 20260817_020; needs short_benefit
--     in all 8 locales.
--
-- Text is byte-identical between evening_32 and morning_33 (same durood,
-- same benefit). English + 7 locales match the tone/register of the
-- surrounding evening_* entries.
--
-- Idempotent — plain UPDATEs, safe to re-run.
-- =============================================================================

BEGIN;

-- English (base column) — this is what pick('short_benefit') returns when
-- no locale-suffixed value matches the active app locale.
UPDATE azkar_items
SET short_benefit = $sb$The Prophet's ﷺ intercession reaches you on the Day of Judgment.$sb$
WHERE id IN ('evening_32', 'morning_33');

-- Urdu
UPDATE azkar_items
SET short_benefit_ur = $sb$قیامت کے دن نبی ﷺ کی شفاعت تم تک پہنچتی ہے۔$sb$
WHERE id IN ('evening_32', 'morning_33');

-- Arabic
UPDATE azkar_items
SET short_benefit_ar = $sb$تنالك شفاعة النبي ﷺ يوم القيامة.$sb$
WHERE id IN ('evening_32', 'morning_33');

-- French
UPDATE azkar_items
SET short_benefit_fr = $sb$L'intercession du Prophète ﷺ te parvient au Jour du Jugement.$sb$
WHERE id IN ('evening_32', 'morning_33');

-- Indonesian
UPDATE azkar_items
SET short_benefit_id = $sb$Syafaat Nabi ﷺ sampai kepadamu pada hari kiamat.$sb$
WHERE id IN ('evening_32', 'morning_33');

-- Malay
UPDATE azkar_items
SET short_benefit_ms = $sb$Syafaat Nabi ﷺ sampai kepadamu pada hari kiamat.$sb$
WHERE id IN ('evening_32', 'morning_33');

-- Russian
UPDATE azkar_items
SET short_benefit_ru = $sb$Заступничество Пророка ﷺ достигнет тебя в Судный день.$sb$
WHERE id IN ('evening_32', 'morning_33');

-- Turkish
UPDATE azkar_items
SET short_benefit_tr = $sb$Kıyamet günü Peygamberimiz ﷺ'in şefaati sana ulaşır.$sb$
WHERE id IN ('evening_32', 'morning_33');

COMMIT;
