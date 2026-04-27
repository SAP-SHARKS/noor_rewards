// V3Y — Spiritual Minimal · YELLOW (soft butter cream + ochre)
// Calm, paper-like, warm. Light desaturated yellows, ochre accents.

const V3Y_THEME = {
  bg: '#FBF6E4',               // butter cream
  surface: '#FFFDF5',
  ink: '#3A2F14',
  inkSoft: '#7A6D52',
  muted: '#B8AE93',
  primary: '#C8932D',          // ochre
  primaryDeep: '#7A5A18',
  primarySoft: '#F5E5B8',
  accent: '#A8743D',
  cardBorder: 'rgba(58,47,20,0.1)',
  pillTrack: '#F0E5C2',
  pillOn: '#FFFDF5',
  pillOnText: '#3A2F14',
  pillText: '#7A6D52',
  serif: '"Instrument Serif", Georgia, serif',
};

function V3YDashboard() {
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
    background: V3Y_THEME.surface, borderRadius: 22, padding: 18,
    border: `1px solid ${V3Y_THEME.cardBorder}`,
  };

  return (
    <div style={{
      background: V3Y_THEME.bg, minHeight: '100%',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V3Y_THEME.ink, paddingBottom: 24, position: 'relative',
    }}>
      <ConfettiBurst show={confetti} color={V3Y_THEME.primary} accent={V3Y_THEME.accent} />

      <div style={{
        padding: '22px 22px 4px', display: 'flex',
        justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <div style={{ fontSize: 11, color: V3Y_THEME.inkSoft, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 600 }}>Fri · 6 Shawwal</div>
          <div style={{
            fontFamily: V3Y_THEME.serif, fontSize: 26,
            letterSpacing: '-0.01em', marginTop: 2, fontWeight: 400,
          }}>
            Assalamu alaikum, <em style={{ fontStyle: 'italic' }}>Ayesha</em>
          </div>
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: '50%',
          border: `1.5px solid ${V3Y_THEME.cardBorder}`,
          background: V3Y_THEME.surface,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontWeight: 600, fontSize: 14, color: V3Y_THEME.ink,
        }}>AR</div>
      </div>

      {/* Hero */}
      <div style={{ padding: '16px 22px 0' }}>
        <div style={{
          ...card, padding: '22px 22px 18px', position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', right: -14, top: -14, opacity: 0.1 }}>
            <GeoStar size={130} color={V3Y_THEME.primary} />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 11, color: V3Y_THEME.inkSoft, letterSpacing: '0.12em', textTransform: 'uppercase', fontWeight: 600 }}>Your points</div>
            <div style={{
              fontFamily: V3Y_THEME.serif, fontSize: 64, fontWeight: 400,
              lineHeight: 1, letterSpacing: '-0.02em', marginTop: 10,
              color: V3Y_THEME.primaryDeep,
              fontVariantNumeric: 'tabular-nums',
            }}>
              {useCountUp(points).toLocaleString()}
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              marginTop: 10, fontSize: 12, color: V3Y_THEME.inkSoft,
            }}>
              <span style={{
                padding: '3px 8px', borderRadius: 999,
                background: V3Y_THEME.primarySoft, color: V3Y_THEME.primaryDeep, fontWeight: 700,
              }}>+127 today</span>
              <span>·</span>
              <span>Rank 284 of 8,420</span>
            </div>

            <button onClick={validate} disabled={validated} style={{
              marginTop: 18, width: '100%', padding: '14px 20px',
              borderRadius: 14, border: 'none',
              background: validated ? V3Y_THEME.primarySoft : V3Y_THEME.primaryDeep,
              color: validated ? V3Y_THEME.primaryDeep : V3Y_THEME.surface,
              fontSize: 14, fontWeight: 600, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit',
            }}>
              {validated ? (
                <><Icon name="check" size={16} strokeWidth={2.5} />Today's points validated</>
              ) : (
                <>Validate today's points<Icon name="arrow" size={16} strokeWidth={2.2} /></>
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
              <div style={{ fontFamily: V3Y_THEME.serif, fontSize: 22, fontWeight: 400, letterSpacing: '-0.01em' }}>
                12 day <em style={{ fontStyle: 'italic' }}>journey</em>
              </div>
              <div style={{ fontSize: 11, color: V3Y_THEME.inkSoft, marginTop: 2 }}>Longest streak · 28 days</div>
            </div>
            <Icon name="flame" size={22} color={V3Y_THEME.primary} strokeWidth={1.8} />
          </div>
          <StreakDots days={4} today={4} accent={V3Y_THEME.primary} muted={V3Y_THEME.muted} />
        </div>
      </div>

      {/* Progress */}
      <div style={{ padding: '14px 22px 0' }}>
        <div style={card}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div style={{ fontFamily: V3Y_THEME.serif, fontSize: 20, letterSpacing: '-0.01em' }}>Progress</div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V3Y_THEME.pillTrack }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '5px 10px', borderRadius: 999, border: 'none',
                  background: tab === t ? V3Y_THEME.surface : 'transparent',
                  color: tab === t ? V3Y_THEME.ink : V3Y_THEME.inkSoft,
                  fontSize: 11, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            <V3YRing pct={pct} color={V3Y_THEME.primary} />
            <div style={{ flex: 1 }}>
              <div style={{
                fontFamily: V3Y_THEME.serif, fontSize: 34, fontWeight: 400,
                lineHeight: 1, letterSpacing: '-0.02em',
              }}>
                {prog.toLocaleString()}
              </div>
              <div style={{ fontSize: 12, color: V3Y_THEME.inkSoft, marginTop: 3 }}>
                of {goal.toLocaleString()} {tab.toLowerCase()} goal
              </div>
              <div style={{ fontSize: 11, color: V3Y_THEME.primary, marginTop: 6, fontWeight: 700 }}>
                {Math.round(pct)}% · On pace
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Practices list */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{
          fontFamily: V3Y_THEME.serif, fontSize: 20, letterSpacing: '-0.01em',
          padding: '0 2px 10px',
        }}>Today's <em>practices</em></div>
        <div style={{
          background: V3Y_THEME.surface, borderRadius: 22,
          border: `1px solid ${V3Y_THEME.cardBorder}`, overflow: 'hidden',
        }}>
          <V3YRow icon="book" label="Read Quran" sub="Surah Al-Mulk · 2/30 pages" pts="+15" color={V3Y_THEME.primary} />
          <V3YDivider />
          <V3YRow icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target} · tap to count`}
            pts={`+${dhikr.count}`} color={V3Y_THEME.primaryDeep} onClick={dhikr.inc} />
          <V3YDivider />
          <V3YRow icon="hands" label="Duas" sub="3 of 5 today" pts="+30" color={V3Y_THEME.accent} />
          <V3YDivider />
          <V3YRow icon="users" label="Invite a friend" sub="+100 per accepted invite" pts="+100" color={V3Y_THEME.ink} muted />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{
          background: V3Y_THEME.primaryDeep, borderRadius: 22, overflow: 'hidden',
          color: V3Y_THEME.bg, position: 'relative',
        }}>
          <div style={{ position: 'absolute', left: -30, bottom: -30, opacity: 0.12 }}>
            <GeoStar size={150} color={V3Y_THEME.primary} />
          </div>
          <div style={{ padding: 22, position: 'relative' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', opacity: 0.75, fontWeight: 700, color: V3Y_THEME.primarySoft }}>Sadaqah · this week</div>
            <div style={{
              fontFamily: V3Y_THEME.serif, fontSize: 24, marginTop: 6,
              lineHeight: 1.2, letterSpacing: '-0.01em',
            }}>
              Clean water for <em style={{ fontStyle: 'italic', color: V3Y_THEME.primary }}>120 families</em> in Yemen
            </div>
            <div style={{ fontSize: 12, opacity: 0.75, marginTop: 6 }}>
              Every 100 points = 1 day of water for a family
            </div>
            <div style={{ marginTop: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, opacity: 0.85 }}>
                <span>7,420 of 10,000 pts</span>
                <span>74%</span>
              </div>
              <div style={{ marginTop: 6, height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.15)' }}>
                <div style={{ height: '100%', width: '74%', background: V3Y_THEME.primary, borderRadius: 999 }} />
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              {[50, 100, 250].map((v) => (
                <button key={v} style={{
                  flex: 1, padding: '9px 0', borderRadius: 999,
                  border: '1.5px solid rgba(255,255,255,0.25)', background: 'transparent',
                  color: V3Y_THEME.bg, fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
                }}>{v} pts</button>
              ))}
              <button style={{
                flex: 1.2, padding: '9px 0', borderRadius: 999,
                border: 'none', background: V3Y_THEME.primary, color: V3Y_THEME.primaryDeep,
                fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
              }}>Donate →</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function V3YRing({ pct, color }) {
  const r = 36;
  const circ = 2 * Math.PI * r;
  const dash = pct / 100 * circ;
  return (
    <svg width="88" height="88" viewBox="0 0 88 88">
      <circle cx="44" cy="44" r={r} fill="none" stroke="#F0E5C2" strokeWidth="6" />
      <circle cx="44" cy="44" r={r} fill="none" stroke={color} strokeWidth="6" strokeLinecap="round"
        strokeDasharray={`${dash} ${circ}`} transform="rotate(-90 44 44)"
        style={{ transition: 'stroke-dasharray .6s' }} />
      <text x="44" y="49" textAnchor="middle" fontSize="18" fontWeight="700" fill={color}
        fontFamily='"Plus Jakarta Sans", system-ui'>{Math.round(pct)}%</text>
    </svg>
  );
}

function V3YDivider() {
  return <div style={{ height: 1, background: V3Y_THEME.cardBorder, margin: '0 18px' }} />;
}

function V3YRow({ icon, label, sub, pts, color, onClick, muted }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 18px', border: 'none',
      background: 'transparent', cursor: onClick ? 'pointer' : 'default',
      fontFamily: 'inherit', textAlign: 'left',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12,
        background: muted ? '#F0E5C2' : `${color}20`,
        color: muted ? V3Y_THEME.ink : color,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={20} strokeWidth={1.9} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: V3Y_THEME.ink }}>{label}</div>
        <div style={{ fontSize: 11, color: V3Y_THEME.inkSoft, marginTop: 2 }}>{sub}</div>
      </div>
      <div style={{
        fontSize: 12, fontWeight: 700, color,
        padding: '4px 10px', borderRadius: 999,
        background: `${color}18`,
      }}>{pts}</div>
    </button>
  );
}

Object.assign(window, { V3YDashboard });
