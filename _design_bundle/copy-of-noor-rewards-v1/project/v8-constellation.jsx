// V8 — Nightsky Constellation
// Deep violet-indigo night sky, points form a constellation that fills as you earn.
// Pearl surfaces, gold stars. Ceremonial, dreamy.

const V8_THEME = {
  bg: '#0F0B2E',
  surfaceDim: 'rgba(255,255,255,0.04)',
  surface: 'rgba(255,255,255,0.07)',
  ink: '#F5F1FF',
  inkSoft: 'rgba(245,241,255,0.72)',
  muted: 'rgba(245,241,255,0.4)',
  violet: '#7C5CFF',           // primary
  violetDeep: '#3B2A8A',
  lavender: '#B5A4FF',
  gold: '#F4C65A',
  pearl: '#E8DFFF',
  rose: '#FF9AB8',
  teal: '#5FE6D4',
  border: 'rgba(245,241,255,0.1)',
  track: 'rgba(245,241,255,0.08)',
  pillTrack: 'rgba(245,241,255,0.08)',
  pillOn: '#F5F1FF',
  pillOnText: '#0F0B2E',
  pillText: 'rgba(245,241,255,0.55)',
  serif: '"Instrument Serif", Georgia, serif',
};

// Twinkling background stars
function V8StarField({ count = 40 }) {
  const stars = React.useMemo(() => Array.from({ length: count }, () => ({
    x: Math.random() * 100,
    y: Math.random() * 100,
    r: Math.random() * 1.3 + 0.3,
    d: Math.random() * 3,
    o: Math.random() * 0.6 + 0.2,
  })), [count]);
  return (
    <svg style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }} width="100%" height="100%" preserveAspectRatio="none" viewBox="0 0 100 100">
      {stars.map((s, i) => (
        <circle key={i} cx={s.x} cy={s.y} r={s.r} fill="#fff" opacity={s.o}>
          <animate attributeName="opacity" values={`${s.o};${s.o * 0.3};${s.o}`} dur={`${2 + s.d}s`} repeatCount="indefinite" />
        </circle>
      ))}
    </svg>
  );
}

// Constellation: connected stars that fill in as progress grows
function V8Constellation({ progress }) {
  // 7 star points forming a loose arc / diamond
  const pts = [
    { x: 20, y: 70 }, { x: 42, y: 50 }, { x: 70, y: 58 },
    { x: 95, y: 40 }, { x: 120, y: 48 }, { x: 148, y: 32 }, { x: 180, y: 42 },
  ];
  const lit = Math.floor(progress * pts.length);
  return (
    <svg width="200" height="90" viewBox="0 0 200 90" style={{ overflow: 'visible' }}>
      <defs>
        <filter id="v8glow"><feGaussianBlur stdDeviation="1.5" /></filter>
        <radialGradient id="v8star">
          <stop offset="0%" stopColor="#fff" />
          <stop offset="100%" stopColor={V8_THEME.gold} />
        </radialGradient>
      </defs>
      {/* lines */}
      {pts.map((p, i) => {
        if (i === 0) return null;
        const prev = pts[i - 1];
        const on = i <= lit;
        return (
          <line key={i} x1={prev.x} y1={prev.y} x2={p.x} y2={p.y}
            stroke={on ? V8_THEME.gold : V8_THEME.muted}
            strokeWidth={on ? 1 : 0.5}
            opacity={on ? 0.8 : 0.3}
            strokeDasharray={on ? '0' : '2 2'}
          />
        );
      })}
      {/* stars */}
      {pts.map((p, i) => {
        const on = i < lit;
        return (
          <g key={i}>
            {on && <circle cx={p.x} cy={p.y} r="8" fill={V8_THEME.gold} opacity="0.3" filter="url(#v8glow)" />}
            <circle cx={p.x} cy={p.y} r={on ? 3 : 2}
              fill={on ? 'url(#v8star)' : V8_THEME.muted} />
          </g>
        );
      })}
    </svg>
  );
}

function V8Dashboard() {
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
  const pct = (prog / goal) * 100;

  return (
    <div style={{
      background: `radial-gradient(ellipse at 50% 0%, ${V8_THEME.violetDeep} 0%, ${V8_THEME.bg} 60%)`,
      minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V8_THEME.ink, paddingBottom: 24, overflow: 'hidden',
    }}>
      <V8StarField count={50} />
      <ConfettiBurst show={confetti} color={V8_THEME.gold} accent={V8_THEME.violet} />

      {/* Header */}
      <div style={{
        position: 'relative', padding: '16px 20px 8px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 40, height: 40, borderRadius: '50%',
            background: `linear-gradient(135deg, ${V8_THEME.violet}, ${V8_THEME.rose})`,
            color: '#fff', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 14,
            boxShadow: `0 0 20px ${V8_THEME.violet}66`,
          }}>AR</div>
          <div>
            <div style={{ fontSize: 11, color: V8_THEME.inkSoft }}>Laylat · Friday eve</div>
            <div style={{ fontSize: 14, fontWeight: 700 }}>Ayesha</div>
          </div>
        </div>
        <button style={{
          width: 40, height: 40, borderRadius: '50%',
          background: V8_THEME.surface, border: `1px solid ${V8_THEME.border}`,
          color: V8_THEME.ink, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="bell" size={18} />
        </button>
      </div>

      {/* Hero — crescent + points + constellation */}
      <div style={{ position: 'relative', padding: '16px 20px 0', textAlign: 'center' }}>
        <div style={{ position: 'relative', width: 120, height: 120, margin: '0 auto' }}>
          {/* glow */}
          <div style={{
            position: 'absolute', inset: -20,
            background: `radial-gradient(circle, ${V8_THEME.gold}33 0%, transparent 60%)`,
          }} />
          <svg width="120" height="120" viewBox="0 0 120 120" style={{ position: 'relative' }}>
            <defs>
              <radialGradient id="v8moon" cx="30%" cy="30%">
                <stop offset="0%" stopColor="#FFF6DC" />
                <stop offset="100%" stopColor={V8_THEME.gold} />
              </radialGradient>
            </defs>
            <path d="M90 60a30 30 0 1 1-24-29.4 24 24 0 0 0 24 29.4z" fill="url(#v8moon)" />
          </svg>
        </div>

        <div style={{ fontSize: 10, color: V8_THEME.inkSoft, letterSpacing: '0.2em', textTransform: 'uppercase', fontWeight: 700, marginTop: 14 }}>
          Your Noor · <span style={{ fontFamily: V8_THEME.serif, fontStyle: 'italic', textTransform: 'none', letterSpacing: 0, color: V8_THEME.gold }}>your light</span>
        </div>
        <div style={{
          fontFamily: V8_THEME.serif, fontSize: 68, fontWeight: 400,
          lineHeight: 1, letterSpacing: '-0.03em', marginTop: 8,
          background: `linear-gradient(180deg, #FFF6DC 0%, ${V8_THEME.gold} 100%)`,
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          fontVariantNumeric: 'tabular-nums',
        }}>
          {useCountUp(points).toLocaleString()}
        </div>
        <div style={{ fontSize: 11, color: V8_THEME.inkSoft, marginTop: 2, fontFamily: V8_THEME.serif, fontStyle: 'italic' }}>
          points · +127 tonight
        </div>

        {/* Constellation */}
        <div style={{ marginTop: 14, display: 'flex', justifyContent: 'center' }}>
          <V8Constellation progress={Math.min(1, points / 2000)} />
        </div>
        <div style={{ fontSize: 10, color: V8_THEME.muted, marginTop: 4, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
          Constellation · 5 of 7 stars lit
        </div>

        {/* Validate */}
        <button onClick={validate} disabled={validated} style={{
          marginTop: 20, width: '100%', padding: '14px 20px',
          borderRadius: 999, border: `1px solid ${V8_THEME.gold}`,
          background: validated ? V8_THEME.surface : `linear-gradient(135deg, ${V8_THEME.gold}, #DFA032)`,
          color: validated ? V8_THEME.ink : V8_THEME.bg,
          fontSize: 14, fontWeight: 700, cursor: validated ? 'default' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontFamily: 'inherit', letterSpacing: '0.02em',
          boxShadow: validated ? 'none' : `0 8px 24px ${V8_THEME.gold}44`,
        }}>
          {validated ? (
            <><Icon name="check" size={16} strokeWidth={2.5} />Sealed tonight · +85</>
          ) : (
            <><Icon name="sparkle" size={16} />Seal tonight's light</>
          )}
        </button>
      </div>

      {/* Streak · moon phases */}
      <div style={{ padding: '20px 20px 0', position: 'relative' }}>
        <div style={{
          background: V8_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V8_THEME.border}`, backdropFilter: 'blur(10px)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 10, color: V8_THEME.inkSoft, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 700 }}>
                Streak of nights
              </div>
              <div style={{ fontFamily: V8_THEME.serif, fontSize: 32, lineHeight: 1, marginTop: 4 }}>
                12 <em style={{ fontStyle: 'italic', fontSize: 16, color: V8_THEME.gold }}>nights</em>
              </div>
            </div>
            <div style={{ fontSize: 11, color: V8_THEME.inkSoft }}>Best · 28</div>
          </div>
          {/* moon phase row */}
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6 }}>
            {['M','T','W','T','F','S','S'].map((l, i) => {
              const done = i < 4;
              const isToday = i === 4;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5 }}>
                  <span style={{ fontSize: 9, color: V8_THEME.muted, fontWeight: 700 }}>{l}</span>
                  <svg width="26" height="26" viewBox="0 0 26 26">
                    <circle cx="13" cy="13" r="10" fill={done ? V8_THEME.gold : 'transparent'} stroke={done ? V8_THEME.gold : V8_THEME.border} strokeWidth="1" strokeDasharray={isToday && !done ? '2 2' : '0'} />
                    {done && <path d="M13 3 a10 10 0 0 1 0 20 z" fill={V8_THEME.bg} opacity="0.4" />}
                  </svg>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Progress */}
      <div style={{ padding: '12px 20px 0' }}>
        <div style={{
          background: V8_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V8_THEME.border}`, backdropFilter: 'blur(10px)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ fontFamily: V8_THEME.serif, fontSize: 20 }}>Journey</div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V8_THEME.pillTrack }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '4px 10px', borderRadius: 999, border: 'none',
                  background: tab === t ? V8_THEME.gold : 'transparent',
                  color: tab === t ? V8_THEME.bg : V8_THEME.inkSoft,
                  fontSize: 10, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ fontFamily: V8_THEME.serif, fontSize: 34, color: V8_THEME.gold, letterSpacing: '-0.02em', lineHeight: 1 }}>
              {prog.toLocaleString()}
            </span>
            <span style={{ fontSize: 12, color: V8_THEME.muted }}>of {goal.toLocaleString()}</span>
          </div>
          <div style={{ marginTop: 10, height: 6, borderRadius: 999, background: V8_THEME.track, position: 'relative', overflow: 'hidden' }}>
            <div style={{
              height: '100%', width: `${pct}%`, borderRadius: 999,
              background: `linear-gradient(90deg, ${V8_THEME.violet}, ${V8_THEME.gold})`,
              boxShadow: `0 0 10px ${V8_THEME.gold}88`,
            }} />
          </div>
        </div>
      </div>

      {/* Practices */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{ fontFamily: V8_THEME.serif, fontSize: 20, padding: '0 0 10px' }}>
          <em style={{ fontStyle: 'italic', color: V8_THEME.gold }}>Earn</em> tonight
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <V8Card icon="book" label="Quran" sub="Al-Mulk · 2/30" pts="+15" color={V8_THEME.violet} />
          <V8Card icon="beads" label="Dhikr" sub={`${dhikr.count}/${dhikr.target}`} pts={`+${dhikr.count}`} color={V8_THEME.gold} onClick={dhikr.inc} tappable />
          <V8Card icon="hands" label="Duas" sub="3 of 5" pts="+30" color={V8_THEME.rose} />
          <V8Card icon="users" label="Invite" sub="+100 / friend" pts="+100" color={V8_THEME.teal} />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{
          background: `linear-gradient(135deg, ${V8_THEME.violet}, ${V8_THEME.violetDeep})`,
          borderRadius: 22, padding: 18, position: 'relative', overflow: 'hidden',
          border: `1px solid ${V8_THEME.gold}44`,
        }}>
          <div style={{ position: 'absolute', right: -20, top: -20, opacity: 0.25 }}>
            <GeoStar size={130} color={V8_THEME.gold} />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 10, color: V8_THEME.gold, letterSpacing: '0.18em', textTransform: 'uppercase', fontWeight: 700 }}>
              Sadaqah Jariyah
            </div>
            <div style={{ fontFamily: V8_THEME.serif, fontSize: 22, lineHeight: 1.2, marginTop: 6 }}>
              <em style={{ fontStyle: 'italic' }}>Light</em> the way for 120 families
            </div>
            <div style={{ fontSize: 11, color: V8_THEME.inkSoft, marginTop: 4 }}>
              Convert your Noor · 100 pts = 1 day of water
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: V8_THEME.inkSoft, marginTop: 14 }}>
              <span>7,420 / 10,000</span>
              <span style={{ color: V8_THEME.gold }}>74%</span>
            </div>
            <div style={{ marginTop: 6, height: 4, borderRadius: 999, background: V8_THEME.track }}>
              <div style={{ height: '100%', width: '74%', borderRadius: 999, background: V8_THEME.gold, boxShadow: `0 0 8px ${V8_THEME.gold}` }} />
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              {[50, 100, 250].map((v) => (
                <button key={v} style={{
                  flex: 1, padding: '9px 0', borderRadius: 999,
                  background: 'transparent', border: `1px solid ${V8_THEME.border}`,
                  color: V8_THEME.ink, fontSize: 11, fontWeight: 600,
                  cursor: 'pointer', fontFamily: 'inherit',
                }}>{v}</button>
              ))}
              <button style={{
                flex: 1.3, padding: '9px 0', borderRadius: 999,
                background: V8_THEME.gold, border: 'none', color: V8_THEME.bg,
                fontSize: 12, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
              }}>Illuminate →</button>
            </div>
          </div>
        </div>
      </div>

    </div>
  );
}

function V8Card({ icon, label, sub, pts, color, onClick, tappable }) {
  return (
    <button onClick={onClick} style={{
      background: V8_THEME.surface,
      border: `1px solid ${color}44`,
      borderRadius: 20, padding: 14,
      textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', color: V8_THEME.ink,
      display: 'flex', flexDirection: 'column', gap: 10,
      backdropFilter: 'blur(8px)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{
          width: 34, height: 34, borderRadius: 10,
          background: `${color}22`, color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 0 12px ${color}44`,
        }}>
          <Icon name={icon} size={17} strokeWidth={1.9} />
        </div>
        <span style={{
          fontSize: 10, fontWeight: 700, color, letterSpacing: '0.05em',
        }}>{pts}</span>
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700 }}>{label}</div>
        <div style={{ fontSize: 11, color: V8_THEME.inkSoft, marginTop: 1 }}>{sub}</div>
        {tappable && (
          <div style={{ fontSize: 9, color, marginTop: 6, fontWeight: 700, letterSpacing: '0.1em' }}>TAP TO COUNT</div>
        )}
      </div>
    </button>
  );
}

Object.assign(window, { V8Dashboard });
