// V3 — Spiritual Minimal
// Calmer surface, muted sage + warm ink, large serif headings, more whitespace.

const V3_THEME = {
  bg: '#F7F3EA',
  surface: '#FFFFFF',
  ink: '#2A3A33',
  inkSoft: '#6B7D76',
  muted: '#A8B3AE',
  primary: '#4A7A65',
  primaryDeep: '#2D5A47',
  gold: '#C89F48',
  accent: '#BC6B5C',
  cardBorder: 'rgba(42,58,51,0.08)',
  pillTrack: '#E9E2D3',
  pillOn: '#2A3A33',
  pillOnText: '#FFFFFF',
  pillText: '#6B7D76',
  serif: '"Instrument Serif", Georgia, serif',
  sans: '"Plus Jakarta Sans", system-ui, sans-serif'
};

function V3Dashboard() {
  const [tab, setTab] = React.useState('Week');
  const [points, setPoints] = React.useState(1247);
  const [validated, setValidated] = React.useState(false);
  const [confetti, setConfetti] = React.useState(false);
  const dhikr = useDhikrCounter(14, 33);

  const validate = () => {
    if (validated) return;
    setConfetti(true);
    setValidated(true);
    setPoints((p) => p + 85);
    setTimeout(() => setConfetti(false), 1200);
  };

  const prog = { Today: 85, Week: 612, Month: 2480 }[tab];
  const goal = { Today: 150, Week: 1000, Month: 4000 }[tab];
  const pct = prog / goal * 100;

  return (
    <div style={{
      background: V3_THEME.bg, minHeight: '100%',
      fontFamily: V3_THEME.sans, color: V3_THEME.ink,
      paddingBottom: 24, position: 'relative'
    }}>
      <ConfettiBurst show={confetti} color={V3_THEME.gold} accent={V3_THEME.primary} />

      {/* Header */}
      <div style={{
        padding: '22px 22px 4px', display: 'flex',
        justifyContent: 'space-between', alignItems: 'center'
      }}>
        <div>
          <div style={{ fontSize: 11, color: V3_THEME.inkSoft, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 600 }}>Fri · 6 Shawwal</div>
          <div style={{
            fontFamily: V3_THEME.serif, fontSize: 26,
            letterSpacing: '-0.01em', marginTop: 2, fontWeight: 400
          }}>
            Assalamu alaikum, <em style={{ fontStyle: 'italic' }}>Ayesha</em>
          </div>
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: '50%',
          border: `1.5px solid ${V3_THEME.cardBorder}`,
          background: V3_THEME.surface,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontWeight: 600, fontSize: 14, color: V3_THEME.ink
        }}>AR</div>
      </div>

      {/* Points hero — understated */}
      <div style={{ padding: '16px 22px 0' }}>
        <div style={{
          background: V3_THEME.surface, borderRadius: 22, padding: '22px 22px 18px',
          border: `1px solid ${V3_THEME.cardBorder}`,
          position: 'relative', overflow: 'hidden'
        }}>
          <div style={{ position: 'absolute', right: -14, top: -14, color: V3_THEME.primary, opacity: 0.07 }}>
            <GeoStar size={130} color={V3_THEME.primary} />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 11, color: V3_THEME.inkSoft, letterSpacing: '0.12em', textTransform: 'uppercase', fontWeight: 600 }}>Your points</div>
            <div style={{
              fontFamily: V3_THEME.serif, fontSize: 64, fontWeight: 400,
              lineHeight: 1, letterSpacing: '-0.02em', marginTop: 10,
              color: V3_THEME.primaryDeep,
              fontVariantNumeric: 'tabular-nums'
            }}>
              {useCountUp(points).toLocaleString()}
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              marginTop: 10, fontSize: 12, color: V3_THEME.inkSoft
            }}>
              <span style={{
                padding: '3px 8px', borderRadius: 999,
                background: '#E8F0EC', color: V3_THEME.primaryDeep, fontWeight: 600
              }}>+127 today</span>
              <span>·</span>
              <span>Rank 284 of 8,420</span>
            </div>

            {/* Validate */}
            <button onClick={validate} disabled={validated} style={{
              marginTop: 18, width: '100%', padding: '14px 20px',
              borderRadius: 14, border: 'none',
              background: validated ? '#E8F0EC' : V3_THEME.primaryDeep,
              color: validated ? V3_THEME.primaryDeep : '#fff',
              fontSize: 14, fontWeight: 600, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit',
              transition: 'all .2s'
            }}>
              {validated ?
              <><Icon name="check" size={16} strokeWidth={2.5} />Today's points validated</> :

              <>Validate today's points<Icon name="arrow" size={16} strokeWidth={2.2} /></>
              }
            </button>
          </div>
        </div>
      </div>

      {/* Streak — calendar week style */}
      <div style={{ padding: '14px 22px 0', color: "rgb(9, 9, 9)" }}>
        <div style={{
          background: V3_THEME.surface, borderRadius: 22, padding: 18,
          border: `1px solid ${V3_THEME.cardBorder}`
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 16 }}>
            <div>
              <div style={{ fontFamily: V3_THEME.serif, fontSize: 22, fontWeight: 400, letterSpacing: '-0.01em' }}>
                12 day <em style={{ fontStyle: 'italic' }}>journey</em>
              </div>
              <div style={{ fontSize: 11, color: V3_THEME.inkSoft, marginTop: 2 }}>Longest streak · 28 days</div>
            </div>
            <Icon name="flame" size={22} color={V3_THEME.gold} strokeWidth={1.8} />
          </div>
          <StreakDots days={4} today={4} accent={V3_THEME.primary} muted={V3_THEME.muted} />
        </div>
      </div>

      {/* Progress */}
      <div style={{ padding: '14px 22px 0' }}>
        <div style={{
          background: V3_THEME.surface, borderRadius: 22, padding: 18,
          border: `1px solid ${V3_THEME.cardBorder}`
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div style={{ fontFamily: V3_THEME.serif, fontSize: 20, letterSpacing: '-0.01em' }}>Progress</div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V3_THEME.pillTrack }}>
              {['Today', 'Week', 'Month'].map((t) =>
              <button key={t} onClick={() => setTab(t)} style={{
                padding: '5px 10px', borderRadius: 999, border: 'none',
                background: tab === t ? V3_THEME.surface : 'transparent',
                color: tab === t ? V3_THEME.ink : V3_THEME.inkSoft,
                fontSize: 11, fontWeight: 600, cursor: 'pointer',
                fontFamily: 'inherit'
              }}>{t}</button>
              )}
            </div>
          </div>

          {/* Ring + stat */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            <V3Ring pct={pct} color={V3_THEME.primary} />
            <div style={{ flex: 1 }}>
              <div style={{
                fontFamily: V3_THEME.serif, fontSize: 34, fontWeight: 400,
                lineHeight: 1, letterSpacing: '-0.02em'
              }}>
                {prog.toLocaleString()}
              </div>
              <div style={{ fontSize: 12, color: V3_THEME.inkSoft, marginTop: 3 }}>
                of {goal.toLocaleString()} {tab.toLowerCase()} goal
              </div>
              <div style={{ fontSize: 11, color: V3_THEME.primary, marginTop: 6, fontWeight: 600 }}>
                {Math.round(pct)}% · On pace
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Practices list */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{
          fontFamily: V3_THEME.serif, fontSize: 20, letterSpacing: '-0.01em',
          padding: '0 2px 10px'
        }}>Today's <em>practices</em></div>
        <div style={{
          background: V3_THEME.surface, borderRadius: 22,
          border: `1px solid ${V3_THEME.cardBorder}`,
          overflow: 'hidden'
        }}>
          <V3Row icon="book" label="Read Quran" sub="Surah Al-Mulk · 2/30 pages" pts="+15" color={V3_THEME.primary} />
          <V3Divider />
          <V3Row
            icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target} · tap to count`}
            pts={`+${dhikr.count}`} color={V3_THEME.gold} onClick={dhikr.inc} active />
          
          <V3Divider />
          <V3Row icon="hands" label="Duas" sub="3 of 5 today" pts="+30" color={V3_THEME.accent} />
          <V3Divider />
          <V3Row icon="users" label="Invite a friend" sub="+100 per accepted invite" pts="+100" color={V3_THEME.ink} muted />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{
          background: V3_THEME.primaryDeep, borderRadius: 22, overflow: 'hidden',
          color: '#F7F3EA', position: 'relative'
        }}>
          <div style={{ position: 'absolute', left: -30, bottom: -30, opacity: 0.1 }}>
            <GeoStar size={150} color={V3_THEME.gold} />
          </div>
          <div style={{ padding: 22, position: 'relative' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', opacity: 0.7, fontWeight: 600 }}>Sadaqah · this week</div>
            <div style={{
              fontFamily: V3_THEME.serif, fontSize: 24, marginTop: 6,
              lineHeight: 1.2, letterSpacing: '-0.01em'
            }}>
              Clean water for <em style={{ fontStyle: 'italic', color: V3_THEME.gold }}>120 families</em> in Yemen
            </div>
            <div style={{ fontSize: 12, opacity: 0.75, marginTop: 6 }}>
              Every 100 points = 1 day of water for a family
            </div>

            <div style={{ marginTop: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, opacity: 0.85 }}>
                <span>7,420 of 10,000 pts</span>
                <span>74%</span>
              </div>
              <div style={{
                marginTop: 6, height: 6, borderRadius: 999,
                background: 'rgba(255,255,255,0.15)'
              }}>
                <div style={{
                  height: '100%', width: '74%',
                  background: V3_THEME.gold, borderRadius: 999
                }} />
              </div>
            </div>

            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              {[50, 100, 250].map((v) =>
              <button key={v} style={{
                flex: 1, padding: '9px 0', borderRadius: 999,
                border: '1.5px solid rgba(255,255,255,0.25)',
                background: 'transparent', color: '#F7F3EA',
                fontSize: 12, fontWeight: 600, cursor: 'pointer',
                fontFamily: 'inherit'
              }}>{v} pts</button>
              )}
              <button style={{
                flex: 1.2, padding: '9px 0', borderRadius: 999,
                border: 'none', background: V3_THEME.gold,
                color: V3_THEME.primaryDeep,
                fontSize: 12, fontWeight: 700, cursor: 'pointer',
                fontFamily: 'inherit'
              }}>Donate →</button>
            </div>
          </div>
        </div>
      </div>
    </div>);

}

function V3Ring({ pct, color }) {
  const r = 36;
  const circ = 2 * Math.PI * r;
  const dash = pct / 100 * circ;
  return (
    <svg width="88" height="88" viewBox="0 0 88 88">
      <circle cx="44" cy="44" r={r} fill="none" stroke="#E9E2D3" strokeWidth="6" />
      <circle
        cx="44" cy="44" r={r} fill="none"
        stroke={color} strokeWidth="6" strokeLinecap="round"
        strokeDasharray={`${dash} ${circ}`}
        transform="rotate(-90 44 44)"
        style={{ transition: 'stroke-dasharray .6s cubic-bezier(.2,.7,.3,1)' }} />
      
      <text
        x="44" y="49" textAnchor="middle"
        fontSize="18" fontWeight="600" fill={color}
        fontFamily='"Plus Jakarta Sans", system-ui'>
        {Math.round(pct)}%</text>
    </svg>);

}

function V3Divider() {
  return <div style={{ height: 1, background: V3_THEME.cardBorder, margin: '0 18px' }} />;
}

function V3Row({ icon, label, sub, pts, color, onClick, active, muted }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 18px', border: 'none',
      background: 'transparent', cursor: onClick ? 'pointer' : 'default',
      fontFamily: 'inherit', textAlign: 'left'
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12,
        background: muted ? '#F2ECDF' : `${color}18`,
        color: muted ? V3_THEME.ink : color,
        display: 'flex', alignItems: 'center', justifyContent: 'center'
      }}>
        <Icon name={icon} size={20} strokeWidth={1.9} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: V3_THEME.ink }}>{label}</div>
        <div style={{ fontSize: 11, color: V3_THEME.inkSoft, marginTop: 2 }}>{sub}</div>
      </div>
      <div style={{
        fontSize: 12, fontWeight: 700, color,
        padding: '4px 10px', borderRadius: 999,
        background: `${color}15`
      }}>{pts}</div>
      {active && <div style={{
        position: 'absolute', marginLeft: -10,
        width: 6, height: 6, borderRadius: '50%',
        background: color
      }} />}
    </button>);

}

Object.assign(window, { V3Dashboard });