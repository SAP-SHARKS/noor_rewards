-- =============================================================================
-- 20260531_030_azkar_animations_rename
--
-- Corrects misleading display NAMES on `azkar_animations`. The original
-- seed used names derived from azkar-intent comments in the Dart source,
-- not from what each painter widget actually paints. This caused several
-- mismatches in the admin UI (e.g., `blinking_eyes` showed as "Cradled
-- Heart", `doors` showed as "Heart Doors" even though the visuals are an
-- eye blink and a heart with light specks respectively).
--
-- The `key` column is the source of truth — the Flutter switch matches
-- on it. Renaming `name` is purely cosmetic; the app behaviour doesn't
-- change. Update per-row so future ones aren't accidentally clobbered.
-- =============================================================================

UPDATE azkar_animations SET name = 'Noor Tree (default)',         description = 'Growing tree with colourful leaf orbs' WHERE key = 'noor_tree';
UPDATE azkar_animations SET name = 'Protection Shield',           description = 'Shield dome forming around the figure' WHERE key = 'shield';
UPDATE azkar_animations SET name = 'Three Quls',                  description = 'Three concentric protection rings around the Qur’an' WHERE key = 'three_quls';
UPDATE azkar_animations SET name = 'Gates of Jannah',             description = 'Two gates swinging open into light' WHERE key = 'gates';
UPDATE azkar_animations SET name = 'Breaking Chains',             description = 'Chains breaking progressively' WHERE key = 'chains';
UPDATE azkar_animations SET name = 'Dua Scene',                   description = 'Praying-hands scene with verse-card overlay' WHERE key = 'dua_scene';
UPDATE azkar_animations SET name = 'Dua Hands',                   description = 'Hands raised in supplication' WHERE key = 'dua_hands';
UPDATE azkar_animations SET name = 'Benefit Text · Morning',      description = 'Reward text card with morning warm palette' WHERE key = 'benefit_morning_1';
UPDATE azkar_animations SET name = 'Benefit Text · Evening',      description = 'Reward text card with evening cool palette' WHERE key = 'benefit_evening_1';
UPDATE azkar_animations SET name = 'Benefit Text · Verse 7',      description = 'Reward text card — last verses of Baqarah' WHERE key = 'benefit_text_7';
UPDATE azkar_animations SET name = 'Benefit Text · Gratitude',    description = 'Reward text card — gratitude' WHERE key = 'benefit_text_16';
UPDATE azkar_animations SET name = 'Benefit Text · Praise',       description = 'Reward text card — divine praise' WHERE key = 'benefit_text_17';
UPDATE azkar_animations SET name = 'Benefit Text · Unseen',       description = 'Reward text card — Knower of the Unseen' WHERE key = 'benefit_text_24';
UPDATE azkar_animations SET name = 'Baqarah Opening Shield',      description = 'Verses opening shield (Baqarah start)' WHERE key = 'baqarah_shield';
UPDATE azkar_animations SET name = 'Baqarah Burden Lifted',       description = 'Last verses — burden lifted from a soul' WHERE key = 'baqarah_burden';
UPDATE azkar_animations SET name = 'Qur’an Complete',             description = 'Qur’an completion / 3 Quls scene' WHERE key = 'quran_complete';
UPDATE azkar_animations SET name = 'Al-Falaq Shield',             description = 'Surah Al-Falaq protection scene' WHERE key = 'falaq_shield';
UPDATE azkar_animations SET name = 'Dawn',                        description = 'Sunrise scene with sun on the horizon' WHERE key = 'dawn';
UPDATE azkar_animations SET name = 'Dawn / Dusk',                 description = 'Night-to-day transition scene' WHERE key = 'dawn_dusk';
UPDATE azkar_animations SET name = 'Night Peace',                 description = 'Calm starry night scene' WHERE key = 'night_peace';
UPDATE azkar_animations SET name = 'Evening Sovereignty',         description = 'Dominion-declaration evening scene' WHERE key = 'evening_sovereignty';
UPDATE azkar_animations SET name = 'Cycle',                       description = 'Day/night cycle scene' WHERE key = 'cycle';
UPDATE azkar_animations SET name = 'Noor Door',                   description = 'Door of divine pleasure opening' WHERE key = 'noor_door';
UPDATE azkar_animations SET name = '6-Direction Guard',           description = 'Afiyah protection from six sides' WHERE key = 'afiyah_guard';
UPDATE azkar_animations SET name = 'Heavy Scales',                description = 'Cosmic-weight tasbih scales' WHERE key = 'heavy_scales';
UPDATE azkar_animations SET name = 'Scales',                      description = 'La ilaha illallah scales' WHERE key = 'scales';
UPDATE azkar_animations SET name = 'Invincible Name',             description = 'Bismillah / perfect-words protection ring' WHERE key = 'invincible';
UPDATE azkar_animations SET name = 'Blinking Eyes',               description = 'Pair of eyes that blink in sequence' WHERE key = 'blinking_eyes';
UPDATE azkar_animations SET name = 'Heart of Light',              description = 'Heart with luminous specks' WHERE key = 'doors';
UPDATE azkar_animations SET name = 'Freedom Flame',               description = 'Freed-from-Hellfire flame scene' WHERE key = 'flame';
UPDATE azkar_animations SET name = 'Three Vessels',               description = 'Body / hearing / sight wellness vessels' WHERE key = 'vessels';
UPDATE azkar_animations SET name = 'Seven Pillars',               description = 'Hasbiyallah seven pillars' WHERE key = 'pillars';
UPDATE azkar_animations SET name = 'Blessings',                   description = 'Morning blessings scene' WHERE key = 'blessings';
UPDATE azkar_animations SET name = 'Ocean of Forgiveness',        description = 'SubhanAllah wa bihamdihi ocean' WHERE key = 'ocean';
UPDATE azkar_animations SET name = 'Salawat Intercession',        description = 'Durood Ibrahim intercession scene' WHERE key = 'salawat_intercession';


-- ── Verify ─────────────────────────────────────────────────────────────────
SELECT key, name, description, icon FROM azkar_animations ORDER BY sort_order, key;
