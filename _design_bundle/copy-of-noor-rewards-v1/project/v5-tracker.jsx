// V5 — Step-tracker ring
// Deep navy bg, single massive progress ring, athletic data-forward layout.
// Like a fitness tracker but for spiritual practice.

const V5_THEME = {
  bg: '#0B1738',
  surface: 'rgba(255,255,255,0.05)',
  surfaceSolid: '#132351',
  ink: '#FFFFFF',
  inkSoft: 'rgba(255,255,255,0.72)',
  muted: 'rgba(255,255,255,0.45)',
  primary: '#3B82F6',       // bright blue
  primaryDim: '#1E3A8A',
  accent: '#60A5FA',
  mint: '#34D5A5',
  amber: '#FBBF24',
  coral: '#F87171',
  border: 'rgba(255,255,255,0.1)',
  track: 'rgba(255,255,255,0.08)',
  pillTrack: 'rgba(255,255,255,0.08)',
  pillOn: '#FFFFFF',
  pillOnText: '#0B1738',
  pillText: 'rgba(255,255,255,0.55)',
};

function V5Dashboard() {
  const [tab, setTab] = React.useState('Today');
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

  // Three-ring data
  const rings = [
    { label: 'Prayer', v: 4, max: 5, color: V5_THEME.primary },
    { label: 'Quran', v: 2, max: 3, color: V5_THEME.mint },
    { label: 'Dhikr', v: dhikr.count, max: dhikr.target, color: V5_THEME.amber },
  ];

  return (
    <div style={{
      background: V5_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V5_THEME.ink, paddingBottom: 24,
      backgroundImage: `radial-gradient(ellipse at 50% -10%, rgba(59,130,246,0.3) 0%, transparent 50%)`,
    }}>
      <ConfettiBurst show={confetti} color={V5_THEME.amber} accent={V5_THEME.mint} />

      {/* Header */}
      <div style={{
        padding: '16px 20px 8px', display: 'flex',
        alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 38, height: 38, borderRadius: '50%',
            background: `linear-gradient(135deg, ${V5_THEME.primary}, ${V5_THEME.accent})`,
            color: '#fff', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 13,
            border: `2px solid ${V5_THEME.border}`,
          }}>AR</div>
          <div>
            <div style={{ fontSize: 11, color: V5_THEME.inkSoft, fontWeight: 500 }}>Fri · 6 Shawwal</div>
            <div style={{ fontSize: 14, fontWeight: 700 }}>Ayesha</div>
          </div>
        </div>
        <button style={{
          width: 38, height: 38, borderRadius: 12,
          background: V5_THEME.surface, border: `1px solid ${V5_THEME.border}`,
          color: V5_THEME.ink, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="bell" size={18} />
        </button>
      </div>

      {/* Massive Ring Hero */}
      <div style={{ padding: '6px 20px 0', textAlign: 'center' }}>
        <div style={{ fontSize: 11, color: V5_THEME.inkSoft, letterSpacing: '0.16em', textTransform: 'uppercase', fontWeight: 700 }}>
          Today's Noor
        </div>
        <div style={{ position: 'relative', width: 260, height: 260, margin: '10px auto 0' }}>
          <V5MultiRing rings={rings} />
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{ fontSize: 11, color: V5_THEME.inkSoft, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Balance</div>
            <div style={{
              fontSize: 52, fontWeight: 800, letterSpacing: '-0.04em',
              lineHeight: 1, marginTop: 4,
              fontVariantNumeric: 'tabular-nums',
              background: `linear-gradient(180deg, #fff, ${V5_THEME.accent})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}>{useCountUp(points).toLocaleString()}</div>
            <div style={{ fontSize: 11, color: V5_THEME.inkSoft, marginTop: 4, fontWeight: 600 }}>+127 today · pts</div>
          </div>
        </div>

        {/* Ring legend */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 16, marginTop: 14 }}>
          {rings.map((r) => (
            <div key={r.label} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 8, height: 8, borderRadius: '50%', background: r.color }} />
              <span style={{ fontSize: 11, color: V5_THEME.inkSoft, fontWeight: 600 }}>
                {r.label} <span style={{ color: V5_THEME.ink }}>{r.v}/{r.max}</span>
              </span>
            </div>
          ))}
        </div>

        {/* Validate CTA */}
        <button onClick={validate} disabled={validated} style={{
          marginTop: 18, width: '100%', padding: '15px 20px',
          borderRadius: 16, border: 'none',
          background: validated ? V5_THEME.surface : V5_THEME.ink,
          color: validated ? V5_THEME.ink : V5_THEME.bg,
          fontSize: 14, fontWeight: 800, cursor: validated ? 'default' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontFamily: 'inherit', letterSpacing: '-0.01em',
          boxShadow: validated ? 'none' : '0 8px 20px rgba(255,255,255,0.15)',
        }}>
          {validated ? (
            <><Icon name="check" size={18} strokeWidth={3} />Validated · +85</>
          ) : (
            <>VALIDATE TODAY'S POINTS<Icon name="arrow" size={16} strokeWidth={3} /></>
          )}
        </button>
      </div>

      {/* Streak + progress row */}
      <div style={{ padding: '18px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <div style={{
          background: V5_THEME.surface, borderRadius: 20, padding: 14,
          border: `1px solid ${V5_THEME.border}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="flame" size={14} color={V5_THEME.amber} strokeWidth={2.4} />
            <span style={{ fontSize: 10, color: V5_THEME.inkSoft, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Streak</span>
          </div>
          <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: '-0.03em', marginTop: 6, lineHeight: 1 }}>
            12<span style={{ fontSize: 14, color: V5_THEME.inkSoft, fontWeight: 600 }}> days</span>
          </div>
          <div style={{ display: 'flex', gap: 3, marginTop: 10 }}>
            {[1,1,1,1,0,0,0].map((d, i) => (
              <span key={i} style={{
                flex: 1, height: 4, borderRadius: 999,
                background: d ? V5_THEME.amber : V5_THEME.track,
              }} />
            ))}
          </div>
        </div>

        <div style={{
          background: V5_THEME.surface, borderRadius: 20, padding: 14,
          border: `1px solid ${V5_THEME.border}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="target" size={14} color={V5_THEME.primary} strokeWidth={2.2} />
            <span style={{ fontSize: 10, color: V5_THEME.inkSoft, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Week</span>
          </div>
          <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: '-0.03em', marginTop: 6, lineHeight: 1 }}>
            612
          </div>
          <div style={{ fontSize: 10, color: V5_THEME.muted, marginTop: 2 }}>of 1,000 goal</div>
          <div style={{ marginTop: 6, height: 4, borderRadius: 999, background: V5_THEME.track }}>
            <div style={{ height: '100%', width: '61%', background: V5_THEME.primary, borderRadius: 999 }} />
          </div>
        </div>
      </div>

      {/* Period switcher + bars */}
      <div style={{ padding: '12px 20px 0' }}>
        <div style={{
          background: V5_THEME.surface, borderRadius: 20, padding: 16,
          border: `1px solid ${V5_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ fontSize: 13, fontWeight: 700 }}>Activity</div>
            <div style={{ display: 'flex', gap: 3 }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '4px 9px', borderRadius: 999, border: 'none',
                  background: tab === t ? V5_THEME.ink : 'transparent',
                  color: tab === t ? V5_THEME.bg : V5_THEME.inkSoft,
                  fontSize: 10, fontWeight: 700, cursor: 'pointer',
                  fontFamily: 'inherit',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.03em' }}>{prog.toLocaleString()}</span>
            <span style={{ fontSize: 12, color: V5_THEME.muted }}>/ {goal.toLocaleString()} pts · {Math.round(pct)}%</span>
          </div>
          <div style={{ display: 'flex', gap: 5, alignItems: 'flex-end', marginTop: 10, height: 42 }}>
            {[34, 48, 62, 41, 72, 88, 55].map((h, i) => {
              const isToday = i === 5;
              return (
                <div key={i} style={{
                  flex: 1, height: `${h}%`, minHeight: 4,
                  borderRadius: 4,
                  background: isToday ? V5_THEME.primary : V5_THEME.accent,
                  opacity: isToday ? 1 : 0.4,
                }} />
              );
            })}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 5 }}>
            {['M','T','W','T','F','S','S'].map((l, i) => (
              <span key={i} style={{ fontSize: 9, color: V5_THEME.muted, fontWeight: 600, flex: 1, textAlign: 'center' }}>{l}</span>
            ))}
          </div>
        </div>
      </div>

      {/* Quick actions — pill row */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 10, color: V5_THEME.inkSoft, letterSpacing: '0.05em' }}>
          QUICK ACTIONS
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <V5Pill icon="book" label="Quran" color={V5_THEME.primary} />
          <V5Pill icon="beads" label={`Dhikr · ${dhikr.count}`} color={V5_THEME.amber} onClick={dhikr.inc} active />
          <V5Pill icon="hands" label="Duas" color={V5_THEME.mint} />
          <V5Pill icon="users" label="Invite" color={V5_THEME.accent} />
          <V5Pill icon="mosque" label="Prayer" color={V5_THEME.coral} />
          <V5Pill icon="calendar" label="History" color={V5_THEME.muted} subtle />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V5_THEME.surfaceSolid, borderRadius: 20, padding: 16,
          border: `1px solid ${V5_THEME.border}`, overflow: 'hidden', position: 'relative',
        }}>
          <div style={{
            position: 'absolute', right: -20, top: -20, opacity: 0.12,
          }}>
            <GeoStar size={140} color={V5_THEME.accent} />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: V5_THEME.inkSoft, fontWeight: 700 }}>
              <Icon name="heart" size={12} color={V5_THEME.coral} strokeWidth={2.4} />
              SADAQAH · WEEKLY
            </div>
            <div style={{ fontSize: 16, fontWeight: 800, marginTop: 6, letterSpacing: '-0.01em' }}>
              Clean water · Yemen
            </div>
            <div style={{ fontSize: 11, color: V5_THEME.inkSoft, marginTop: 2 }}>
              100 pts = 1 day for a family
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: V5_THEME.inkSoft, marginTop: 12, fontWeight: 600 }}>
              <span>7,420 / 10,000 pts</span>
              <span style={{ color: V5_THEME.accent }}>74%</span>
            </div>
            <div style={{ marginTop: 6, height: 5, borderRadius: 999, background: V5_THEME.track }}>
              <div style={{
                height: '100%', width: '74%', borderRadius: 999,
                background: `linear-gradient(90deg, ${V5_THEME.primary}, ${V5_THEME.mint})`,
              }} />
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              {[50, 100, 250].map((v) => (
                <button key={v} style={{
                  flex: 1, padding: '9px 0', borderRadius: 999,
                  background: V5_THEME.track, border: `1px solid ${V5_THEME.border}`,
                  color: V5_THEME.ink, fontSize: 11, fontWeight: 700,
                  cursor: 'pointer', fontFamily: 'inherit',
                }}>{v}</button>
              ))}
              <button style={{
                flex: 1.2, padding: '9px 0', borderRadius: 999,
                background: V5_THEME.ink, border: 'none', color: V5_THEME.bg,
                fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
              }}>Donate →</button>
            </div>
          </div>
        </div>
      </div>

    </div>
  );
}

function V5MultiRing({ rings }) {
  const sizes = [120, 98, 76]; // radii
  return (
    <svg width="260" height="260" viewBox="0 0 260 260">
      <defs>
        <filter id="v5glow">
          <feGaussianBlur stdDeviation="3" result="b" />
          <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
      </defs>
      {rings.map((r, i) => {
        const radius = sizes[i];
        const circ = 2 * Math.PI * radius;
        const pct = Math.min(1, r.v / r.max);
        return (
          <g key={r.label}>
            <circle cx="130" cy="130" r={radius} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="10" />
            <circle
              cx="130" cy="130" r={radius} fill="none"
              stroke={r.color} strokeWidth="10" strokeLinecap="round"
              strokeDasharray={`${circ * pct} ${circ}`}
              transform="rotate(-90 130 130)"
              filter="url(#v5glow)"
              style={{ transition: 'stroke-dasharray .6s cubic-bezier(.2,.7,.3,1)' }}
            />
          </g>
        );
      })}
    </svg>
  );
}

function V5Pill({ icon, label, color, onClick, active, subtle }) {
  return (
    <button onClick={onClick} style={{
      background: active ? `${color}22` : V5_THEME.surface,
      border: `1px solid ${active ? `${color}55` : V5_THEME.border}`,
      borderRadius: 16, padding: '12px 10px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      cursor: 'pointer', fontFamily: 'inherit', color: V5_THEME.ink,
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 10,
        background: subtle ? V5_THEME.track : `${color}22`,
        color: subtle ? V5_THEME.muted : color,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={16} strokeWidth={2} />
      </div>
      <span style={{ fontSize: 11, fontWeight: 600, color: subtle ? V5_THEME.muted : V5_THEME.ink }}>{label}</span>
    </button>
  );
}

Object.assign(window, { V5Dashboard });
