-- =============================================================================
-- 20260607_070_daily_duas_illustration_audit
--
-- Sets the illustration pool for every Daily Dua, same selection rule as
-- the prior audits: an existing Morning/Evening illustration may be
-- reused only when the dua's theme matches; otherwise create a dedicated
-- text-illustration card.
--
-- ~20 mappings use existing M/E artwork (invincible, vessels, doors,
-- flame, chains, shield, pillars, salawat_intercession, gates, noor_door,
-- scales, night_peace, dawn, afiyah_guard). ~19 use new text cards
-- registered below.
--
-- Idempotent. Re-runnable.
-- =============================================================================

BEGIN;

-- 1. Register the 19 new text-card keys -----------------------------------
INSERT INTO azkar_animations (key, name, description, icon, sort_order) VALUES
  ('benefit_daily_004', 'Daily · Entering Home',           'Text card: best entry and exit, with His name',          '🏠', 500),
  ('benefit_daily_005', 'Daily · Entering Toilet',         'Text card: refuge from evil jinn',                        '🛡️', 501),
  ('benefit_daily_007', 'Daily · Before Meals',            'Text card: Bismillah keeps Shaytan from sharing',        '🍽️', 502),
  ('benefit_daily_008', 'Daily · Forgetting Bismillah',    'Text card: Bismillah at any moment covers both ends',    '💫', 503),
  ('benefit_daily_009', 'Daily · After Meals',             'Text card: praise after eating — past sins forgiven',    '✨', 504),
  ('benefit_daily_013', 'Daily · Leaving Masjid',          'Text card: asking His bounty leaving His house',         '🚪', 505),
  ('benefit_daily_014', 'Daily · Answering Adhan',         'Text card: respond word by word — enter Paradise',       '📣', 506),
  ('benefit_daily_016', 'Daily · Dua Qunoot',              'Text card: guide me, protect me, guard from evil',       '🤲', 507),
  ('benefit_daily_018', 'Daily · Visiting Graves',         'Text card: peace and well-being for those who preceded', '🌿', 508),
  ('benefit_daily_019', 'Daily · On Journey',              'Text card: glory to Him who subjugated the vehicle',     '🛤️', 509),
  ('benefit_daily_020', 'Daily · Return from Journey',     'Text card: we return repentant, worshipping our Lord',   '🏡', 510),
  ('benefit_daily_021', 'Daily · When Sneezing',           'Text card: Allah loves sneezing — say Alhamdulillah',    '🤧', 511),
  ('benefit_daily_022', 'Daily · Hearing Sneeze',          'Text card: respond with Yarhamukallah',                   '💗', 512),
  ('benefit_daily_023', 'Daily · Reply to Sneezer',        'Text card: reply with Yahdikumullah',                     '🙏', 513),
  ('benefit_daily_027', 'Daily · Dua for Parents',         'Text card: parents raised in rank by your du''a',         '👨‍👩‍👧', 514),
  ('benefit_daily_035', 'Daily · Greatest Name',           'Text card: called upon by His Greatest Name',             '✨', 515),
  ('benefit_daily_036', 'Daily · When Breaking Fast',      'Text card: thirst gone, reward is sure',                  '🌙', 516),
  ('benefit_daily_041', 'Daily · Marriage Du''a',          'Text card: child protected from Shaytan by His name',     '💝', 517),
  ('benefit_daily_044', 'Daily · Salatul Istikhara',       'Text card: ask His guidance before any decision',         '🧭', 518)
ON CONFLICT (key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order;


-- 2. Wipe every existing mapping for daily_dua_* --------------------------
DELETE FROM azkar_item_animations
WHERE azkar_id IN (
  'daily_dua_001','daily_dua_002','daily_dua_003','daily_dua_004','daily_dua_005',
  'daily_dua_006','daily_dua_007','daily_dua_008','daily_dua_009','daily_dua_010',
  'daily_dua_011','daily_dua_012','daily_dua_013','daily_dua_014','daily_dua_015',
  'daily_dua_016','daily_dua_017','daily_dua_018','daily_dua_019','daily_dua_020',
  'daily_dua_021','daily_dua_022','daily_dua_023','daily_dua_024','daily_dua_025',
  'daily_dua_026','daily_dua_027','daily_dua_033','daily_dua_034','daily_dua_035',
  'daily_dua_036','daily_dua_037','daily_dua_038','daily_dua_039','daily_dua_040',
  'daily_dua_041','daily_dua_042','daily_dua_043','daily_dua_044'
);


-- 3. Insert the audited mappings ------------------------------------------
INSERT INTO azkar_item_animations (azkar_id, animation_id, weight, sort_order)
SELECT m.azkar_id, a.id, 1, m.sort_order
FROM (VALUES
  -- Sleep / wake
  ('daily_dua_001', 'night_peace', 0),  -- Upon Going to Sleep
  ('daily_dua_002', 'dawn',        0),  -- Wake up from Sleep

  -- Home
  ('daily_dua_003', 'invincible',         0),  -- Leaving Home (Bismillah tawakkaltu)
  ('daily_dua_004', 'benefit_daily_004',  0),  -- Entering Home

  -- Toilet
  ('daily_dua_005', 'benefit_daily_005',  0),  -- Entering Toilet (refuge from jinn)
  ('daily_dua_006', 'doors',              0),  -- Leaving Toilet (Ghufranaka = istighfar)

  -- Meals
  ('daily_dua_007', 'benefit_daily_007',  0),  -- Before Meals (Bismillah)
  ('daily_dua_008', 'benefit_daily_008',  0),  -- Forgetting Bismillah
  ('daily_dua_009', 'benefit_daily_009',  0),  -- After Meals (sins forgiven)

  -- Wudu
  ('daily_dua_010', 'invincible',         0),  -- Start of Wudu (Bismillah)
  ('daily_dua_011', 'gates',              0),  -- Completion of Wudu (8 gates of Paradise)

  -- Masjid
  ('daily_dua_012', 'noor_door',          0),  -- Entering Masjid (open gates of mercy)
  ('daily_dua_013', 'benefit_daily_013',  0),  -- Leaving Masjid (asking His bounty)

  -- Adhan
  ('daily_dua_014', 'benefit_daily_014',  0),  -- Answering Adhan
  ('daily_dua_015', 'salawat_intercession', 0), -- Dua after Adhan (Wasilah)

  -- Other prayers
  ('daily_dua_016', 'benefit_daily_016',  0),  -- Dua Qunoot
  ('daily_dua_017', 'doors',              0),  -- Janaza (istighfar for deceased)
  ('daily_dua_018', 'benefit_daily_018',  0),  -- Visiting Graves

  -- Journey
  ('daily_dua_019', 'benefit_daily_019',  0),  -- On Journey
  ('daily_dua_020', 'benefit_daily_020',  0),  -- Return from Journey

  -- Sneezing trio
  ('daily_dua_021', 'benefit_daily_021',  0),  -- When Sneezing
  ('daily_dua_022', 'benefit_daily_022',  0),  -- Hearing Someone Sneeze
  ('daily_dua_023', 'benefit_daily_023',  0),  -- Sneezer's Reply

  -- Health
  ('daily_dua_024', 'vessels',            0),  -- For Good Health 7x
  ('daily_dua_025', 'vessels',            0),  -- Cure of any Illness
  ('daily_dua_026', 'afiyah_guard',       0),  -- Children Protection
  ('daily_dua_026', 'invincible',         1),
  ('daily_dua_043', 'vessels',            0),  -- When Visiting Sick

  -- Parents / refuge / Allah's names
  ('daily_dua_027', 'benefit_daily_027',  0),  -- Dua for Parents
  ('daily_dua_033', 'shield',             0),  -- Seek Refuge (grave/hell/dajjal)
  ('daily_dua_034', 'pillars',            0),  -- Hasbunallah wa ni'mal wakeel
  ('daily_dua_035', 'benefit_daily_035',  0),  -- Greatest Name of Allah

  -- Fasting / Hellfire / Shirk
  ('daily_dua_036', 'benefit_daily_036',  0),  -- When Breaking Fast
  ('daily_dua_037', 'flame',              0),  -- Protection from Hellfire
  ('daily_dua_038', 'shield',             0),  -- Fear of Shirk (refuge from)

  -- Distress
  ('daily_dua_039', 'chains',             0),  -- Difficult Affairs
  ('daily_dua_040', 'chains',             0),  -- Anxiety and Sorrow

  -- Marriage / market / istikhara
  ('daily_dua_041', 'benefit_daily_041',  0),  -- Marriage du'a
  ('daily_dua_042', 'scales',             0),  -- Entering Market (unparalleled reward)
  ('daily_dua_044', 'benefit_daily_044',  0)   -- Salatul Istikhara
) AS m(azkar_id, anim_key, sort_order)
JOIN azkar_animations a ON a.key = m.anim_key
ON CONFLICT (azkar_id, animation_id) DO NOTHING;


-- 4. Verify ---------------------------------------------------------------
SELECT
  ai.id      AS azkar_id,
  ai.title,
  a.key      AS animation_key
FROM azkar_items ai
LEFT JOIN azkar_item_animations aia ON aia.azkar_id = ai.id
LEFT JOIN azkar_animations a       ON a.id = aia.animation_id
WHERE ai.category_id = 'daily_duas'
ORDER BY ai.sort_order, aia.sort_order;

COMMIT;
