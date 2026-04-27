// V2 — Bento Grid dashboard
// Asymmetric tiled grid; dense, scan-friendly, playful color blocks.

const V2_THEME = {
  bg: '#EFEAE0',
  surface: '#FFFFFF',
  ink: '#1B2421',
  inkSoft: '#5B6B65',
  muted: '#A3ACA8',
  primary: '#178C6F',
  primaryDeep: '#0A5A45',
  gold: '#F2B83D',
  plum: '#6D4A8C',
  peach: '#FF8E6E',
  sky: '#5BA8D4',
  pillTrack: '#E7DFCE',
  pillOn: '#FFFFFF',
  pillOnText: '#1B2421',
  pillText: '#7B8884',
};

function V2Dashboard() {
  const [tab, setTab] = React.useState('Week');
  const [points, setPoints] = React.useState(1247);
  const [validated, setValidated] = React.useState(false);
  const [confetti, setConfetti] = React.useState(false);
  const dhikr = useDhikrCounter(21, 33);

  const validate = () => {
    if (validated) return;
    setConfetti(true);
    setValidated(true);
    setPoints((p) => p + 85);
    setTimeout(() => setConfetti(false), 1200);
  };

  const prog = {
    Today: 85, Week: 612, Month: 2480,
  }[tab];
  const goal = { Today: 150, Week: 1000, Month: 4000 }[tab];

  return (
    <div style={{
      background: V2_THEME.bg, minHeight: '100%',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V2_THEME.ink, paddingBottom: 24, position: 'relative',
    }}>
      <ConfettiBurst show={confetti} color={V2_THEME.gold} accent={V2_THEME.primary} />

      {/* Compact header */}
      <div style={{
        padding: '16px 16px 10px', display: 'flex',
        alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 12,
            background: V2_THEME.ink, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 15,
          }}>AR</div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.01em' }}>Ayesha</div>
            <div style={{ fontSize: 11, color: V2_THEME.inkSoft }}>Level 7 · Munir</div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={v2IconBtn()}><Icon name="calendar" size={18} /></button>
          <button style={v2IconBtn()}><Icon name="bell" size={18} /></button>
        </div>
      </div>

      {/* Bento grid */}
      <div style={{
        padding: '6px 16px 0',
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gridAutoRows: 'minmax(0, auto)',
        gap: 10,
      }}>
        {/* Points tile — spans 2 cols */}
        <div style={{
          gridColumn: 'span 2',
          background: V2_THEME.ink,
          color: '#fff', borderRadius: 22, padding: 18,
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.12, color: V2_THEME.gold }}>
            <GeoStar size={180} color={V2_THEME.gold} />
          </div>
          <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.12em', opacity: 0.6, fontWeight: 600 }}>Total points</div>
              <div style={{ marginTop: 4 }}>
                <PointsNumber value={points} size={44} color="#fff" label="pts" labelColor="#fff" />
              </div>
            </div>
            <button onClick={validate} disabled={validated} style={{
              padding: '10px 14px', borderRadius: 14, border: 'none',
              background: validated ? 'rgba(255,255,255,0.15)' : V2_THEME.gold,
              color: validated ? '#fff' : V2_THEME.ink, fontSize: 13, fontWeight: 700,
              cursor: validated ? 'default' : 'pointer', fontFamily: 'inherit',
              display: 'flex', alignItems: 'center', gap: 6,
              boxShadow: validated ? 'none' : '0 4px 14px rgba(242,184,61,0.4)',
            }}>
              {validated ? <><Icon name="check" size={14} strokeWidth={2.5} />Done</> : <>Validate<Icon name="arrow" size={14} strokeWidth={2.5} /></>}
            </button>
          </div>
          <div style={{ marginTop: 12, display: 'flex', gap: 14, fontSize: 11, color: 'rgba(255,255,255,0.7)' }}>
            <span>+127 today</span>
            <span>·</span>
            <span>Rank #284</span>
            <span>·</span>
            <span>Next level in 253 pts</span>
          </div>
        </div>

        {/* Streak tile */}
        <div style={{
          background: V2_THEME.primary, color: '#fff',
          borderRadius: 22, padding: 16, overflow: 'hidden',
          position: 'relative',
        }}>
          <Icon name="flame" size={22} color={V2_THEME.gold} strokeWidth={2.2} />
          <div style={{ fontSize: 42, fontWeight: 700, letterSpacing: '-0.03em', marginTop: 6, lineHeight: 1 }}>12</div>
          <div style={{ fontSize: 12, opacity: 0.85, marginTop: 2 }}>day streak</div>
          <div style={{ display: 'flex', gap: 3, marginTop: 10 }}>
            {[1,1,1,1,0,0,0].map((d, i) => (
              <span key={i} style={{
                flex: 1, height: 4, borderRadius: 999,
                background: d ? V2_THEME.gold : 'rgba(255,255,255,0.25)',
              }} />
            ))}
          </div>
          <div style={{ fontSize: 10, opacity: 0.75, marginTop: 6 }}>M T W T · F S S</div>
        </div>

        {/* Progress tile */}
        <div style={{ background: V2_THEME.surface, borderRadius: 22, padding: 16 }}>
          <div style={{ display: 'flex', gap: 4, marginBottom: 10 }}>
            {['Today', 'Week', 'Month'].map((t) => (
              <button key={t} onClick={() => setTab(t)} style={{
                padding: '4px 8px', borderRadius: 999, border: 'none',
                background: tab === t ? V2_THEME.ink : 'transparent',
                color: tab === t ? '#fff' : V2_THEME.inkSoft,
                fontSize: 11, fontWeight: 600, cursor: 'pointer',
                fontFamily: 'inherit',
              }}>{t}</button>
            ))}
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1 }}>
            {prog.toLocaleString()}
          </div>
          <div style={{ fontSize: 11, color: V2_THEME.inkSoft, marginTop: 2 }}>of {goal.toLocaleString()}</div>
          <div style={{
            marginTop: 10, height: 6, borderRadius: 999,
            background: V2_THEME.pillTrack,
          }}>
            <div style={{
              height: '100%', width: `${(prog / goal) * 100}%`,
              background: V2_THEME.primary, borderRadius: 999,
            }} />
          </div>
        </div>

        {/* Quran tile */}
        <div style={{
          background: V2_THEME.plum, color: '#fff',
          borderRadius: 22, padding: 16, position: 'relative', overflow: 'hidden',
          cursor: 'pointer',
        }}>
          <div style={{ position: 'absolute', right: -10, bottom: -10, opacity: 0.18 }}>
            <GeoStar size={80} color="#fff" />
          </div>
          <div style={{ position: 'relative' }}>
            <Icon name="book" size={22} strokeWidth={1.8} />
            <div style={{ fontSize: 15, fontWeight: 700, marginTop: 10 }}>Read Quran</div>
            <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>Surah Al-Mulk</div>
            <div style={{
              marginTop: 10, display: 'inline-flex',
              padding: '3px 8px', borderRadius: 999,
              background: 'rgba(255,255,255,0.18)', fontSize: 10, fontWeight: 700,
            }}>+15 / page</div>
          </div>
        </div>

        {/* Dhikr tile — interactive */}
        <div style={{
          background: V2_THEME.gold, color: V2_THEME.ink,
          borderRadius: 22, padding: 16, position: 'relative', overflow: 'hidden',
          cursor: 'pointer',
        }} onClick={dhikr.inc}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Icon name="beads" size={22} strokeWidth={1.8} />
            <span style={{ fontSize: 10, fontWeight: 700, padding: '3px 6px', borderRadius: 999, background: 'rgba(0,0,0,0.12)' }}>TAP</span>
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em', marginTop: 10, lineHeight: 1 }}>
            {dhikr.count}<span style={{ fontSize: 14, opacity: 0.6 }}> / {dhikr.target}</span>
          </div>
          <div style={{ fontSize: 11, opacity: 0.75, marginTop: 2 }}>SubhanAllah</div>
        </div>

        {/* Duas tile */}
        <div style={{ background: V2_THEME.peach, color: '#fff', borderRadius: 22, padding: 16 }}>
          <Icon name="hands" size={22} strokeWidth={1.8} />
          <div style={{ fontSize: 15, fontWeight: 700, marginTop: 10 }}>Daily Duas</div>
          <div style={{ fontSize: 11, opacity: 0.9, marginTop: 2 }}>3 of 5 today</div>
          <div style={{ display: 'flex', gap: 3, marginTop: 10 }}>
            {[1,1,1,0,0].map((d, i) => (
              <span key={i} style={{
                flex: 1, height: 4, borderRadius: 999,
                background: d ? '#fff' : 'rgba(255,255,255,0.35)',
              }} />
            ))}
          </div>
        </div>

        {/* Invite tile */}
        <div style={{
          background: V2_THEME.sky, color: '#fff',
          borderRadius: 22, padding: 16, position: 'relative', overflow: 'hidden',
        }}>
          <Icon name="users" size={22} strokeWidth={1.8} />
          <div style={{ fontSize: 15, fontWeight: 700, marginTop: 10 }}>Invite</div>
          <div style={{ fontSize: 11, opacity: 0.9, marginTop: 2 }}>+100 per friend</div>
          <div style={{
            marginTop: 10, display: 'inline-flex', alignItems: 'center', gap: 4,
            padding: '4px 8px', borderRadius: 999,
            background: 'rgba(255,255,255,0.22)', fontSize: 10, fontWeight: 700,
          }}>
            <Icon name="plus" size={12} strokeWidth={2.5} />Share link
          </div>
        </div>

        {/* Donation card — spans 2 */}
        <div style={{
          gridColumn: 'span 2',
          background: V2_THEME.surface, borderRadius: 22, overflow: 'hidden',
        }}>
          <div style={{ padding: 16, display: 'flex', gap: 14, alignItems: 'flex-start' }}>
            <div style={{
              width: 56, height: 56, borderRadius: 14,
              background: `linear-gradient(135deg, ${V2_THEME.peach}, #E5436F)`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#fff', flexShrink: 0,
            }}>
              <Icon name="heart" size={26} strokeWidth={2} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.1em', color: V2_THEME.inkSoft, fontWeight: 600 }}>Featured Sadaqah</div>
              <div style={{ fontSize: 14, fontWeight: 700, marginTop: 2, lineHeight: 1.25 }}>Clean water · Yemen</div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: V2_THEME.inkSoft, marginTop: 8 }}>
                <span>7,420 / 10,000 pts</span>
                <span style={{ color: V2_THEME.ink, fontWeight: 700 }}>74%</span>
              </div>
              <div style={{
                marginTop: 5, height: 6, borderRadius: 999, background: V2_THEME.pillTrack,
              }}>
                <div style={{
                  height: '100%', width: '74%',
                  background: `linear-gradient(90deg, ${V2_THEME.peach}, #E5436F)`,
                  borderRadius: 999,
                }} />
              </div>
            </div>
            <button style={{
              padding: '8px 12px', borderRadius: 12, border: 'none',
              background: V2_THEME.ink, color: '#fff', fontSize: 12, fontWeight: 700,
              cursor: 'pointer', fontFamily: 'inherit', flexShrink: 0,
            }}>Donate</button>
          </div>
        </div>

      </div>
    </div>
  );
}

function v2IconBtn() {
  return {
    width: 36, height: 36, borderRadius: 12, border: 'none',
    background: V2_THEME.surface, color: V2_THEME.ink,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer',
  };
}

Object.assign(window, { V2Dashboard });
