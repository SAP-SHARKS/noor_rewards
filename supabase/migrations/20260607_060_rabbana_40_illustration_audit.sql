-- =============================================================================
-- 20260607_060_rabbana_40_illustration_audit
--
-- Sets the illustration pool for every Rabbana 40 dua, following the same
-- selection rule used in the sleep / after-Salah audits:
--   • An existing Morning/Evening illustration may be reused only when the
--     dua's theme matches it (forgiveness → doors, hellfire refuge → flame,
--     etc.).
--   • Anything outside the clean M/E pool gets a dedicated text-illustration
--     card showing the dua's theme + Qur'an reference.
--
-- 18 azkar map to existing M/E artwork; 22 get new text cards. The new
-- text-card keys are added to azkar_animations first (so admin sees them
-- in the picker) and rendered by Dart cases in `_buildIllustration`.
--
-- Idempotent: existing rabbana mappings are wiped, then re-inserted.
-- =============================================================================

BEGIN;

-- 1. Register the 22 new text-card keys ------------------------------------
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_rabbana_001', 'Rabbana · Ibrahim builds the Kaaba',  'Text card: dua of acceptance after building His House',           '🕋', 400),
  ('benefit_rabbana_002', 'Rabbana · Ummah success',             'Text card: affirm Islam, ask success for the Muslim Ummah',       '🕌', 401),
  ('benefit_rabbana_006', 'Rabbana · Trials we can bear',        'Text card: not to be tested beyond what we can endure',          '🌿', 402),
  ('benefit_rabbana_008', 'Rabbana · Mercy + guidance',          'Text card: asking His mercy, to be among the rightly guided',    '✨', 403),
  ('benefit_rabbana_009', 'Rabbana · Belief in the Day',         'Text card: affirming belief in the Day He will gather mankind',  '🌅', 404),
  ('benefit_rabbana_011', 'Rabbana · Witness to truth',          'Text card: written among the witnesses to His message',          '📜', 405),
  ('benefit_rabbana_014', 'Rabbana · Fate of wrongdoers',        'Text card: reflection on cause/effect and the Hereafter',        '⚖️', 406),
  ('benefit_rabbana_015', 'Rabbana · We heard, we believed',     'Text card: heeding the call of submission',                       '👂', 407),
  ('benefit_rabbana_017', 'Rabbana · Not disgraced',             'Text card: not to be disgraced on the Day He fulfils His promise','🛡️', 408),
  ('benefit_rabbana_018', 'Rabbana · Testify truth',             'Text card: verbal affirmation of belief in Muhammad ﷺ',           '🗣️', 409),
  ('benefit_rabbana_022', 'Rabbana · Refuse falsehood',          'Text card: dua of Suhaib refusing to return to disbelief',       '🛡️', 410),
  ('benefit_rabbana_026', 'Rabbana · Establish prayer',          'Text card: Ibrahim''s dua for family who pray',                   '🤲', 411),
  ('benefit_rabbana_028', 'Rabbana · Companions of the Cave',    'Text card: dua of refuge in the Cave',                            '🏔️', 412),
  ('benefit_rabbana_029', 'Rabbana · I am with you',             'Text card: Harun + Musa before Firawn',                           '🌟', 413),
  ('benefit_rabbana_030', 'Rabbana · Most Merciful',             'Text card: calling Him by Ar-Rahim',                              '💗', 414),
  ('benefit_rabbana_032', 'Rabbana · Coolness of the eyes',      'Text card: family, righteous spouses, godfearing leadership',     '👨‍👩‍👧', 415),
  ('benefit_rabbana_033', 'Rabbana · Garden of Eden praise',     'Text card: He is Forgiving, Appreciative',                        '🌳', 416),
  ('benefit_rabbana_035', 'Rabbana · Reunited in Jannah',        'Text card: uniting descendants in Jannah by His mercy',           '👨‍👩‍👧‍👦', 417),
  ('benefit_rabbana_036', 'Rabbana · Remove resentment',         'Text card: cleansing the heart toward fellow believers',         '🕊️', 418),
  ('benefit_rabbana_037', 'Rabbana · Ar-Ra''uf Ar-Raheem',       'Text card: praising His beautiful names',                          '✨', 419),
  ('benefit_rabbana_039', 'Rabbana · Victory of believers',      'Text card: Ibrahim''s dua not to be made objects of torment',     '⚔️', 420),
  ('benefit_rabbana_040', 'Rabbana · Perfect our light',         'Text card: light on the Day of Judgment',                         '🌟', 421)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;


-- 2. Wipe every existing mapping for rabbana_001..040 ---------------------
DELETE FROM azkar_item_animations
WHERE azkar_id IN (
  'rabbana_001','rabbana_002','rabbana_003','rabbana_004','rabbana_005',
  'rabbana_006','rabbana_007','rabbana_008','rabbana_009','rabbana_010',
  'rabbana_011','rabbana_012','rabbana_013','rabbana_014','rabbana_015',
  'rabbana_016','rabbana_017','rabbana_018','rabbana_019','rabbana_020',
  'rabbana_021','rabbana_022','rabbana_023','rabbana_024','rabbana_025',
  'rabbana_026','rabbana_027','rabbana_028','rabbana_029','rabbana_030',
  'rabbana_031','rabbana_032','rabbana_033','rabbana_034','rabbana_035',
  'rabbana_036','rabbana_037','rabbana_038','rabbana_039','rabbana_040'
);


-- 3. Insert the audited mappings ------------------------------------------
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, m.sort_order
FROM (VALUES
  -- ── Ibrahim builds the Kaaba ──────────────────────────────────────────
  ('rabbana_001', 'benefit_rabbana_001', 0),
  ('rabbana_002', 'benefit_rabbana_002', 0),

  -- ── Comprehensive du'a (good in dunya/akhira + refuge from Fire) ──────
  ('rabbana_003', 'flame', 0),

  -- ── Dawud: protection, patience, victory ──────────────────────────────
  ('rabbana_004', 'shield', 0),

  -- ── Tawbah / istighfar ────────────────────────────────────────────────
  ('rabbana_005', 'doors', 0),

  -- ── Trials we can bear (Baqarah 286) ──────────────────────────────────
  ('rabbana_006', 'benefit_rabbana_006', 0),

  -- ── Last verses of Baqarah — istighfar + baqarah_burden ───────────────
  ('rabbana_007', 'doors',          0),
  ('rabbana_007', 'baqarah_burden', 1),

  -- ── Mercy + guidance ──────────────────────────────────────────────────
  ('rabbana_008', 'benefit_rabbana_008', 0),

  -- ── Belief in the Day of Gathering ────────────────────────────────────
  ('rabbana_009', 'benefit_rabbana_009', 0),

  -- ── Repentance + refuge from the Fire ─────────────────────────────────
  ('rabbana_010', 'doors', 0),
  ('rabbana_010', 'flame', 1),

  -- ── Witnesses to the truth ────────────────────────────────────────────
  ('rabbana_011', 'benefit_rabbana_011', 0),

  -- ── Steadfastness on the battlefield ──────────────────────────────────
  ('rabbana_012', 'pillars', 0),

  -- ── Praise + refuge from Jahannam ─────────────────────────────────────
  ('rabbana_013', 'flame', 0),

  -- ── Fate of the wrongdoers (reflection) ───────────────────────────────
  ('rabbana_014', 'benefit_rabbana_014', 0),

  -- ── Heeded the caller ─────────────────────────────────────────────────
  ('rabbana_015', 'benefit_rabbana_015', 0),

  -- ── Forgiveness + dying guided ────────────────────────────────────────
  ('rabbana_016', 'doors', 0),

  -- ── Not disgraced on the Day of Judgment ──────────────────────────────
  ('rabbana_017', 'benefit_rabbana_017', 0),

  -- ── Verbal testimony of truth ─────────────────────────────────────────
  ('rabbana_018', 'benefit_rabbana_018', 0),

  -- ── Isa: provision from the heavens ───────────────────────────────────
  ('rabbana_019', 'vessels', 0),

  -- ── Adam: repentance after sinning ────────────────────────────────────
  ('rabbana_020', 'doors', 0),

  -- ── Protection from the wrongdoers' fate ──────────────────────────────
  ('rabbana_021', 'shield', 0),

  -- ── Suhaib: refuse falsehood ──────────────────────────────────────────
  ('rabbana_022', 'benefit_rabbana_022', 0),

  -- ── Musa: patience and righteous death ────────────────────────────────
  ('rabbana_023', 'pillars', 0),

  -- ── Musa's companions: protection from unjust people ──────────────────
  ('rabbana_024', 'shield', 0),

  -- ── Complete trust and reliance ───────────────────────────────────────
  ('rabbana_025', 'pillars', 0),

  -- ── Ibrahim: family who establish prayer ──────────────────────────────
  ('rabbana_026', 'benefit_rabbana_026', 0),

  -- ── Ibrahim: forgive me and my parents ────────────────────────────────
  ('rabbana_027', 'doors', 0),

  -- ── Companions of the Cave ────────────────────────────────────────────
  ('rabbana_028', 'benefit_rabbana_028', 0),

  -- ── Harun + Musa before Firawn ────────────────────────────────────────
  ('rabbana_029', 'benefit_rabbana_029', 0),

  -- ── Ar-Rahim (Most Merciful) ──────────────────────────────────────────
  ('rabbana_030', 'benefit_rabbana_030', 0),

  -- ── Protection from Jahannam ──────────────────────────────────────────
  ('rabbana_031', 'flame', 0),

  -- ── Coolness of the eyes (family) ─────────────────────────────────────
  ('rabbana_032', 'benefit_rabbana_032', 0),

  -- ── Garden of Eden praise ─────────────────────────────────────────────
  ('rabbana_033', 'benefit_rabbana_033', 0),

  -- ── Mercy for all who sought istighfar ────────────────────────────────
  ('rabbana_034', 'doors', 0),

  -- ── Uniting believers with descendants in Jannah ──────────────────────
  ('rabbana_035', 'benefit_rabbana_035', 0),

  -- ── Ummah unity, no resentment ────────────────────────────────────────
  ('rabbana_036', 'benefit_rabbana_036', 0),

  -- ── Ar-Ra'uf + Ar-Raheem ──────────────────────────────────────────────
  ('rabbana_037', 'benefit_rabbana_037', 0),

  -- ── Complete tawakkul, final destination ──────────────────────────────
  ('rabbana_038', 'pillars', 0),

  -- ── Ibrahim: victorious over disbelievers ─────────────────────────────
  ('rabbana_039', 'benefit_rabbana_039', 0),

  -- ── Light on the Day of Judgment ──────────────────────────────────────
  ('rabbana_040', 'benefit_rabbana_040', 0)
) AS m(azkar_id, anim_key, sort_order)
JOIN azkar_animations a ON a.key = m.anim_key
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- 4. Verify ---------------------------------------------------------------
-- Show the resulting animation pool for every Rabbana azkar so you can
-- spot-check the mappings.
SELECT
  ai.id       AS azkar_id,
  ai.title,
  a.key       AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.category_id = 'rabbana_40'
ORDER BY ai.sort_order, aia.sort_order;

COMMIT;
