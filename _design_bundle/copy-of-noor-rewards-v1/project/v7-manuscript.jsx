// V7 — Terracotta Manuscript
// Illuminated-manuscript inspired: parchment, terracotta, indigo, saffron.
// Display serif for numbers, arabesque borders, "ledger" metaphor for points.

const V7_THEME = {
  bg: '#F6EBD9',              // parchment
  parchment: '#FBF3E2',
  surface: '#FFFFFF',
  ink: '#2B1F1A',
  inkSoft: '#6B5A4E',
  muted: '#A89681',
  terra: '#B04A2C',           // terracotta primary
  terraDeep: '#7A2E16',
  saffron: '#E8A84A',
  indigo: '#3A3A8B',
  teal: '#417575',
  border: 'rgba(43,31,26,0.12)',
  rule: 'rgba(43,31,26,0.2)',
  track: '#EADBC0',
  pillTrack: '#EADBC0',
  pillOn: '#B04A2C',
  pillOnText: '#FFFFFF',
  pillText: '#6B5A4E',
  serif: '"Instrument Serif", "Cormorant Garamond", Georgia, serif',
};

// Arabesque corner flourish
function V7Flourish({ size = 24, color, rotate = 0 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ transform: `rotate(${rotate}deg)` }}>
      <g fill="none" stroke={color} strokeWidth="1" strokeLinecap="round">
        <path d="M2 2 L12 2 M2 2 L2 12" />
        <path d="M6 2 Q6 6, 2 6" />
        <path d="M10 2 Q10 10, 2 10" />
        <circle cx="6" cy="6" r="1" fill={color} />
      </g>
    </svg>
  );
}

function V7Dashboard() {
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

  return (
    <div style={{
      background: V7_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V7_THEME.ink, paddingBottom: 24,
      backgroundImage: `
        radial-gradient(circle at 20% 10%, rgba(176,74,44,0.05) 0%, transparent 30%),
        radial-gradient(circle at 80% 80%, rgba(58,58,139,0.04) 0%, transparent 30%)
      `,
    }}>
      <ConfettiBurst show={confetti} color={V7_THEME.saffron} accent={V7_THEME.terra} />

      {/* Header with illumination border */}
      <div style={{ padding: '18px 20px 8px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: 10, color: V7_THEME.inkSoft, letterSpacing: '0.2em', textTransform: 'uppercase', fontWeight: 700 }}>
              ﴾ The Ledger ﴿
            </div>
            <div style={{ fontFamily: V7_THEME.serif, fontSize: 24, fontWeight: 400, marginTop: 2 }}>
              <em style={{ fontStyle: 'italic', color: V7_THEME.terra }}>As-salāmu</em> ʿalaykum
            </div>
          </div>
          <div style={{
            width: 42, height: 42, borderRadius: '50%',
            background: V7_THEME.terra, color: V7_THEME.parchment,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 14, fontFamily: V7_THEME.serif,
            border: `2px solid ${V7_THEME.saffron}`,
          }}>AR</div>
        </div>
      </div>

      {/* Points — illuminated panel */}
      <div style={{ padding: '8px 20px 0' }}>
        <div style={{
          background: V7_THEME.parchment, borderRadius: 4,
          border: `2px solid ${V7_THEME.terra}`,
          padding: 4, position: 'relative',
        }}>
          <div style={{
            border: `1px solid ${V7_THEME.terra}`, padding: '18px 18px 16px',
            position: 'relative',
          }}>
            {/* corner flourishes */}
            <div style={{ position: 'absolute', top: 6, left: 6 }}><V7Flourish size={20} color={V7_THEME.terra} /></div>
            <div style={{ position: 'absolute', top: 6, right: 6 }}><V7Flourish size={20} color={V7_THEME.terra} rotate={90} /></div>
            <div style={{ position: 'absolute', bottom: 6, left: 6 }}><V7Flourish size={20} color={V7_THEME.terra} rotate={-90} /></div>
            <div style={{ position: 'absolute', bottom: 6, right: 6 }}><V7Flourish size={20} color={V7_THEME.terra} rotate={180} /></div>

            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 10, color: V7_THEME.inkSoft, letterSpacing: '0.24em', textTransform: 'uppercase', fontWeight: 700 }}>
                · Your Noor ·
              </div>
              <div style={{
                fontFamily: V7_THEME.serif, fontSize: 72, fontWeight: 400,
                lineHeight: 1, letterSpacing: '-0.03em', marginTop: 8,
                color: V7_THEME.terraDeep,
                fontVariantNumeric: 'tabular-nums',
              }}>
                {useCountUp(points).toLocaleString()}
              </div>
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 8,
                marginTop: 10, fontSize: 11, color: V7_THEME.inkSoft,
                fontFamily: V7_THEME.serif, fontStyle: 'italic',
              }}>
                <span>—</span>
                <span>+127 inscribed today</span>
                <span>—</span>
              </div>
            </div>

            <button onClick={validate} disabled={validated} style={{
              marginTop: 16, width: '100%', padding: '12px 20px',
              border: `1.5px solid ${V7_THEME.terraDeep}`,
              borderRadius: 0,
              background: validated ? V7_THEME.parchment : V7_THEME.terra,
              color: validated ? V7_THEME.terraDeep : V7_THEME.parchment,
              fontSize: 12, fontWeight: 700, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit', letterSpacing: '0.14em', textTransform: 'uppercase',
              transition: 'all .2s',
            }}>
              {validated ? (
                <><Icon name="check" size={14} strokeWidth={2.5} />Sealed · +85</>
              ) : (
                <>Seal today's ledger</>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Streak — calendar page with flourish */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V7_THEME.surface, borderRadius: 10, padding: 16,
          border: `1px solid ${V7_THEME.border}`,
          boxShadow: '0 1px 0 rgba(43,31,26,0.04)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div>
              <div style={{ fontSize: 10, color: V7_THEME.inkSoft, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 700 }}>
                Consecutive days
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
                <span style={{ fontFamily: V7_THEME.serif, fontSize: 34, color: V7_THEME.terra, lineHeight: 1 }}>12</span>
                <span style={{ fontFamily: V7_THEME.serif, fontSize: 14, fontStyle: 'italic', color: V7_THEME.inkSoft }}>· longest 28</span>
              </div>
            </div>
            <div style={{
              padding: '5px 10px',
              background: V7_THEME.saffron + '33',
              color: V7_THEME.terraDeep,
              fontSize: 10, fontWeight: 700, letterSpacing: '0.1em',
              textTransform: 'uppercase',
              border: `1px solid ${V7_THEME.saffron}`,
            }}>
              Blessed
            </div>
          </div>
          <div style={{ marginTop: 14 }}>
            <StreakDots days={4} today={4} accent={V7_THEME.terra} muted={V7_THEME.muted} />
          </div>
        </div>
      </div>

      {/* Progress — handwritten style */}
      <div style={{ padding: '12px 20px 0' }}>
        <div style={{
          background: V7_THEME.surface, borderRadius: 10, padding: 16,
          border: `1px solid ${V7_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ fontFamily: V7_THEME.serif, fontSize: 20, letterSpacing: '-0.01em' }}>
              Your <em style={{ fontStyle: 'italic' }}>progress</em>
            </div>
            <div style={{ display: 'flex', gap: 0, border: `1px solid ${V7_THEME.border}`, borderRadius: 2 }}>
              {['Today', 'Week', 'Month'].map((t, i, arr) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '5px 10px', border: 'none',
                  background: tab === t ? V7_THEME.terra : 'transparent',
                  color: tab === t ? '#fff' : V7_THEME.ink,
                  fontSize: 10, fontWeight: 700, cursor: 'pointer',
                  letterSpacing: '0.12em', textTransform: 'uppercase',
                  fontFamily: 'inherit',
                  borderRight: i < arr.length - 1 ? `1px solid ${V7_THEME.border}` : 'none',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{ fontFamily: V7_THEME.serif, fontSize: 40, color: V7_THEME.terraDeep, lineHeight: 1, letterSpacing: '-0.02em' }}>
              {prog.toLocaleString()}
            </span>
            <span style={{ fontFamily: V7_THEME.serif, fontSize: 14, fontStyle: 'italic', color: V7_THEME.inkSoft }}>
              / {goal.toLocaleString()}
            </span>
          </div>
          {/* hand-ruled progress */}
          <div style={{
            marginTop: 14, height: 3, background: V7_THEME.track,
            position: 'relative',
          }}>
            <div style={{
              position: 'absolute', left: 0, top: 0, bottom: 0,
              width: `${(prog / goal) * 100}%`, background: V7_THEME.terra,
              transition: 'width .6s',
            }} />
            {/* tick marks */}
            {[0, 25, 50, 75, 100].map((p) => (
              <div key={p} style={{
                position: 'absolute', left: `${p}%`, top: -4, bottom: -4,
                width: 1, background: V7_THEME.rule,
              }} />
            ))}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: V7_THEME.serif, fontStyle: 'italic', fontSize: 11, color: V7_THEME.inkSoft, marginTop: 6 }}>
            <span>0</span><span>{goal.toLocaleString()}</span>
          </div>
        </div>
      </div>

      {/* Practices — as a manuscript index */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          fontFamily: V7_THEME.serif, fontSize: 20, letterSpacing: '-0.01em',
          padding: '0 0 10px', display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <span style={{ flex: '0 0 auto' }}>Daily <em style={{ fontStyle: 'italic', color: V7_THEME.terra }}>practices</em></span>
          <span style={{ flex: 1, height: 1, background: V7_THEME.rule }} />
        </div>

        <div style={{
          background: V7_THEME.surface, borderRadius: 10,
          border: `1px solid ${V7_THEME.border}`, overflow: 'hidden',
        }}>
          <V7Row icon="book" label="Quran" sub="Al-Mulk · 2 of 30" num="ⅰ" pts="+30" color={V7_THEME.indigo} />
          <V7Row icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target}`} num="ⅱ" pts={`+${dhikr.count}`} color={V7_THEME.saffron} onClick={dhikr.inc} active />
          <V7Row icon="hands" label="Duas" sub="3 / 5 today" num="ⅲ" pts="+30" color={V7_THEME.teal} />
          <V7Row icon="users" label="Invite a friend" sub="+100 per invite" num="ⅳ" pts="+100" color={V7_THEME.terra} last />
        </div>
      </div>

      {/* Donation — waqf / endowment feel */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{
          background: V7_THEME.indigo, borderRadius: 4,
          border: `2px solid ${V7_THEME.saffron}`, padding: 4,
          color: V7_THEME.parchment, position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            border: `1px solid ${V7_THEME.saffron}`, padding: 18,
            position: 'relative',
          }}>
            <div style={{ position: 'absolute', right: -10, top: -10, opacity: 0.15 }}>
              <GeoStar size={120} color={V7_THEME.saffron} />
            </div>
            <div style={{ position: 'relative' }}>
              <div style={{ fontSize: 10, letterSpacing: '0.22em', textTransform: 'uppercase', color: V7_THEME.saffron, fontWeight: 700 }}>
                ﴾ Waqf · Endowment ﴿
              </div>
              <div style={{
                fontFamily: V7_THEME.serif, fontSize: 22, marginTop: 6,
                lineHeight: 1.25, letterSpacing: '-0.01em',
              }}>
                Clean water for <em style={{ color: V7_THEME.saffron, fontStyle: 'italic' }}>120 families</em>
              </div>
              <div style={{ fontSize: 11, opacity: 0.75, marginTop: 4, fontFamily: V7_THEME.serif, fontStyle: 'italic' }}>
                Every 100 Noor · one day of water
              </div>

              <div style={{ marginTop: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, fontFamily: V7_THEME.serif, fontStyle: 'italic' }}>
                  <span>7,420 of 10,000 raised</span>
                  <span>74%</span>
                </div>
                <div style={{ marginTop: 6, height: 2, background: 'rgba(255,255,255,0.15)' }}>
                  <div style={{ height: '100%', width: '74%', background: V7_THEME.saffron }} />
                </div>
              </div>

              <div style={{ display: 'flex', gap: 6, marginTop: 14 }}>
                {[50, 100, 250].map((v) => (
                  <button key={v} style={{
                    flex: 1, padding: '9px 0',
                    background: 'transparent',
                    border: `1px solid ${V7_THEME.saffron}66`,
                    color: V7_THEME.parchment,
                    fontSize: 11, fontWeight: 600, cursor: 'pointer',
                    fontFamily: V7_THEME.serif, fontStyle: 'italic',
                  }}>{v} pts</button>
                ))}
                <button style={{
                  flex: 1.4, padding: '9px 0',
                  background: V7_THEME.saffron, border: 'none',
                  color: V7_THEME.indigo,
                  fontSize: 11, fontWeight: 700, cursor: 'pointer',
                  fontFamily: 'inherit', letterSpacing: '0.12em', textTransform: 'uppercase',
                }}>Endow →</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function V7Row({ icon, label, sub, num, pts, color, onClick, active, last }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 16px', border: 'none',
      borderBottom: last ? 'none' : `1px solid ${V7_THEME.border}`,
      background: active ? V7_THEME.parchment : 'transparent',
      cursor: onClick ? 'pointer' : 'default',
      fontFamily: 'inherit', textAlign: 'left',
    }}>
      <div style={{
        fontFamily: V7_THEME.serif, fontSize: 14, fontStyle: 'italic',
        color: V7_THEME.muted, width: 16, flexShrink: 0,
      }}>{num}</div>
      <div style={{
        width: 36, height: 36,
        border: `1px solid ${color}`, color,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={18} strokeWidth={1.8} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: V7_THEME.ink }}>{label}</div>
        <div style={{ fontSize: 11, color: V7_THEME.inkSoft, marginTop: 2, fontFamily: V7_THEME.serif, fontStyle: 'italic' }}>{sub}</div>
      </div>
      <div style={{
        fontFamily: V7_THEME.serif, fontSize: 16, color,
        letterSpacing: '-0.01em',
      }}>{pts}</div>
    </button>
  );
}

Object.assign(window, { V7Dashboard });
