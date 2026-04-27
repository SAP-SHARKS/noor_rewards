// V3Y2 — Butter Cream Minimal · NEON YELLOW (#f9f506)
// Pure neon-lemon accent on warm cream paper. Clean, minimal, high-contrast.

const V3Y2_THEME = {
  bg: '#FBF7E8',
  surface: '#FFFFFF',
  ink: '#1A1808',
  inkSoft: '#6B6749',
  muted: '#B8B393',
  primary: '#F9F506',           // exact neon yellow
  primaryDeep: '#7A7700',       // muted regular shade
  primarySoft: '#FFFCB8',       // soft regular shade
  ochre: '#A89320',
  cardBorder: 'rgba(26,24,8,0.08)',
  pillTrack: '#F4F0D8',
  serif: '"Instrument Serif", Georgia, serif',
};

function V3Y2Dashboard() {
  const [tab, setTab] = React.useState('Week');
  const [points, setPoints] = React.useState(1247);
  const [validated, setValidated] = React.useState(false);
  const [confetti, setConfetti] = React.useState(false);
  const dhikr = useDhikrCounter(14, 33);

  const validate = () => {
    if (validated) return;
    setConfetti(true); setValidated(true);
    setPoints((p) => p + 85);
    setTimeout(() => setConfetti(false), 1200);
  };

  const prog = { Today: 85, Week: 612, Month: 2480 }[tab];
  const goal = { Today: 150, Week: 1000, Month: 4000 }[tab];
  const pct = prog / goal * 100;
  const card = {
    background: V3Y2_THEME.surface, borderRadius: 22, padding: 18,
    border: `1px solid ${V3Y2_THEME.cardBorder}`,
  };

  return (
    <div style={{
      background: V3Y2_THEME.bg, minHeight: '100%',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V3Y2_THEME.ink, paddingBottom: 24, position: 'relative',
    }}>
      <ConfettiBurst show={confetti} color={V3Y2_THEME.primary} accent={V3Y2_THEME.ink} />

      <div style={{
        padding: '22px 22px 4px', display: 'flex',
        justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <div style={{ fontSize: 11, color: V3Y2_THEME.inkSoft, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 600 }}>Fri · 6 Shawwal</div>
          <div style={{ fontFamily: V3Y2_THEME.serif, fontSize: 26, marginTop: 2, fontWeight: 400 }}>
            Assalamu alaikum, <em style={{ fontStyle: 'italic' }}>Ayesha</em>
          </div>
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: '50%',
          background: V3Y2_THEME.primary, color: V3Y2_THEME.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontWeight: 800, fontSize: 14,
        }}>AR</div>
      </div>

      {/* Hero — neon block */}
      <div style={{ padding: '16px 22px 0' }}>
        <div style={{
          background: V3Y2_THEME.primary, borderRadius: 24,
          padding: '24px 22px 20px', position: 'relative', overflow: 'hidden',
          color: V3Y2_THEME.ink,
        }}>
          <div style={{ position: 'absolute', right: -14, top: -14, opacity: 0.2 }}>
            <GeoStar size={130} color={V3Y2_THEME.ink} />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 11, letterSpacing: '0.12em', textTransform: 'uppercase', fontWeight: 700, opacity: 0.7 }}>Your points</div>
            <div style={{
              fontFamily: V3Y2_THEME.serif, fontSize: 68, fontWeight: 400,
              lineHeight: 1, letterSpacing: '-0.03em', marginTop: 6,
              fontVariantNumeric: 'tabular-nums',
            }}>
              {useCountUp(points).toLocaleString()}
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              marginTop: 10, fontSize: 12, fontWeight: 700,
            }}>
              <span style={{
                padding: '3px 8px', borderRadius: 999,
                background: V3Y2_THEME.ink, color: V3Y2_THEME.primary,
              }}>+127 today</span>
              <span style={{ opacity: 0.7 }}>·</span>
              <span style={{ opacity: 0.75 }}>Rank 284</span>
            </div>

            <button onClick={validate} disabled={validated} style={{
              marginTop: 18, width: '100%', padding: '14px 20px',
              borderRadius: 14, border: 'none',
              background: validated ? 'rgba(26,24,8,0.12)' : V3Y2_THEME.ink,
              color: validated ? V3Y2_THEME.ink : V3Y2_THEME.primary,
              fontSize: 14, fontWeight: 700, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit',
            }}>
              {validated ? (
                <><Icon name="check" size={16} strokeWidth={2.5} />Validated · +85 pts</>
              ) : (
                <>Validate today's points<Icon name="arrow" size={16} strokeWidth={2.4} /></>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Streak */}
      <div style={{ padding: '14px 22px 0' }}>
        <div style={card}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 16 }}>
            <div>
              <div style={{ fontFamily: V3Y2_THEME.serif, fontSize: 22, fontWeight: 400 }}>
                12 day <em style={{ fontStyle: 'italic' }}>journey</em>
              </div>
              <div style={{ fontSize: 11, color: V3Y2_THEME.inkSoft, marginTop: 2 }}>Longest streak · 28 days</div>
            </div>
            <div style={{
              padding: '6px 10px', borderRadius: 999,
              background: V3Y2_THEME.primary, color: V3Y2_THEME.ink,
              fontSize: 11, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 4,
            }}>
              <Icon name="flame" size={12} strokeWidth={2.4} />
              On fire
            </div>
          </div>
          <StreakDots days={4} today={4} accent={V3Y2_THEME.ink} muted={V3Y2_THEME.muted} />
        </div>
      </div>

      {/* Progress */}
      <div style={{ padding: '14px 22px 0' }}>
        <div style={card}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div style={{ fontFamily: V3Y2_THEME.serif, fontSize: 20 }}>Progress</div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V3Y2_THEME.pillTrack }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '5px 10px', borderRadius: 999, border: 'none',
                  background: tab === t ? V3Y2_THEME.ink : 'transparent',
                  color: tab === t ? V3Y2_THEME.primary : V3Y2_THEME.inkSoft,
                  fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            {/* ring */}
            <svg width="88" height="88" viewBox="0 0 88 88">
              <circle cx="44" cy="44" r="36" fill="none" stroke={V3Y2_THEME.pillTrack} strokeWidth="8" />
              <circle cx="44" cy="44" r="36" fill="none" stroke={V3Y2_THEME.primary} strokeWidth="8" strokeLinecap="round"
                strokeDasharray={`${(pct / 100) * 226} 240`} transform="rotate(-90 44 44)" />
              <text x="44" y="50" textAnchor="middle" fontSize="18" fontWeight="800" fill={V3Y2_THEME.ink}>{Math.round(pct)}%</text>
            </svg>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: V3Y2_THEME.serif, fontSize: 34, lineHeight: 1, letterSpacing: '-0.02em' }}>
                {prog.toLocaleString()}
              </div>
              <div style={{ fontSize: 12, color: V3Y2_THEME.inkSoft, marginTop: 3 }}>
                of {goal.toLocaleString()} {tab.toLowerCase()} goal
              </div>
              <div style={{
                display: 'inline-block', marginTop: 6,
                padding: '2px 8px', borderRadius: 999,
                background: V3Y2_THEME.primary, color: V3Y2_THEME.ink,
                fontSize: 10, fontWeight: 800, letterSpacing: '0.05em', textTransform: 'uppercase',
              }}>On pace</div>
            </div>
          </div>
        </div>
      </div>

      {/* Practices */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{ fontFamily: V3Y2_THEME.serif, fontSize: 20, padding: '0 2px 10px' }}>
          Today's <em>practices</em>
        </div>
        <div style={{
          background: V3Y2_THEME.surface, borderRadius: 22,
          border: `1px solid ${V3Y2_THEME.cardBorder}`, overflow: 'hidden',
        }}>
          <V3Y2Row icon="book" label="Read Quran" sub="Surah Al-Mulk · 2/30 pages" pts="+15" />
          <V3Y2Divider />
          <V3Y2Row icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target} · tap to count`}
            pts={`+${dhikr.count}`} onClick={dhikr.inc} highlight />
          <V3Y2Divider />
          <V3Y2Row icon="hands" label="Duas" sub="3 of 5 today" pts="+30" />
          <V3Y2Divider />
          <V3Y2Row icon="users" label="Invite a friend" sub="+100 per accepted invite" pts="+100" />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{
          background: V3Y2_THEME.ink, borderRadius: 22, overflow: 'hidden',
          color: V3Y2_THEME.bg, position: 'relative',
        }}>
          <div style={{ position: 'absolute', left: -30, bottom: -30, opacity: 0.18 }}>
            <GeoStar size={150} color={V3Y2_THEME.primary} />
          </div>
          <div style={{ padding: 22, position: 'relative' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', fontWeight: 800, color: V3Y2_THEME.primary }}>
              Sadaqah · this week
            </div>
            <div style={{ fontFamily: V3Y2_THEME.serif, fontSize: 24, marginTop: 6, lineHeight: 1.2 }}>
              Clean water for <em style={{ fontStyle: 'italic', color: V3Y2_THEME.primary }}>120 families</em> in Yemen
            </div>
            <div style={{ fontSize: 12, opacity: 0.75, marginTop: 6 }}>
              Every 100 points = 1 day of water for a family
            </div>
            <div style={{ marginTop: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, opacity: 0.85 }}>
                <span>7,420 of 10,000 pts</span>
                <span style={{ color: V3Y2_THEME.primary, fontWeight: 800 }}>74%</span>
              </div>
              <div style={{ marginTop: 6, height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.15)' }}>
                <div style={{ height: '100%', width: '74%', background: V3Y2_THEME.primary, borderRadius: 999 }} />
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              {[50, 100, 250].map((v) => (
                <button key={v} style={{
                  flex: 1, padding: '9px 0', borderRadius: 999,
                  border: '1.5px solid rgba(255,255,255,0.25)', background: 'transparent',
                  color: V3Y2_THEME.bg, fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
                }}>{v} pts</button>
              ))}
              <button style={{
                flex: 1.2, padding: '9px 0', borderRadius: 999,
                border: 'none', background: V3Y2_THEME.primary, color: V3Y2_THEME.ink,
                fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
              }}>Donate →</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function V3Y2Divider() {
  return <div style={{ height: 1, background: V3Y2_THEME.cardBorder, margin: '0 18px' }} />;
}

function V3Y2Row({ icon, label, sub, pts, onClick, highlight }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 18px', border: 'none',
      background: highlight ? V3Y2_THEME.primary + '22' : 'transparent',
      cursor: onClick ? 'pointer' : 'default', fontFamily: 'inherit', textAlign: 'left',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12,
        background: highlight ? V3Y2_THEME.primary : V3Y2_THEME.pillTrack,
        color: V3Y2_THEME.ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={20} strokeWidth={1.9} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: V3Y2_THEME.ink }}>{label}</div>
        <div style={{ fontSize: 11, color: V3Y2_THEME.inkSoft, marginTop: 2 }}>{sub}</div>
      </div>
      <div style={{
        fontSize: 12, fontWeight: 800, color: V3Y2_THEME.ink,
        padding: '4px 10px', borderRadius: 999,
        background: V3Y2_THEME.primary,
      }}>{pts}</div>
    </button>
  );
}

Object.assign(window, { V3Y2Dashboard });
