// V9Y — Orchard Garden · YELLOW (honey + sage + cream)
// Warm honey-yellow garden. Plants stay sage; sun & blooms golden.

const V9Y_THEME = {
  bg: '#FFF4D2',                // honey wash
  surface: '#FFFFFF',
  cream: '#FFFAE3',
  ink: '#2A2410',
  inkSoft: '#766B47',
  muted: '#B8AC85',
  primary: '#7A8C3A',           // olive/sage
  primaryDeep: '#4D5C20',
  honey: '#FFC83D',             // honey
  honeyDeep: '#D89A1E',
  butter: '#FFE89A',
  sky: '#FFE89A',               // override sky→pale gold for cohesion
  plum: '#E8A84A',              // amber
  soil: '#8A5A3B',
  border: 'rgba(42,36,16,0.1)',
  track: '#F4E5B0',
  display: '"Fraunces", "Instrument Serif", Georgia, serif',
};

function V9YPlant({ grow = 0.5, size = 64 }) {
  const leaves = Math.ceil(grow * 4);
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <path d="M16 48 L48 48 L44 60 L20 60 Z" fill={V9Y_THEME.soil} />
      <ellipse cx="32" cy="48" rx="16" ry="3" fill="#6D4528" />
      <path d={`M32 48 Q32 ${48 - grow * 30} 32 ${30 - grow * 10}`} stroke={V9Y_THEME.primary} strokeWidth="2" fill="none" strokeLinecap="round" />
      {leaves >= 1 && <path d="M32 40 Q24 36 22 30 Q28 30 32 38" fill={V9Y_THEME.primary} />}
      {leaves >= 2 && <path d="M32 36 Q40 32 42 26 Q36 26 32 34" fill={V9Y_THEME.primary} />}
      {leaves >= 3 && <path d="M32 28 Q26 24 24 18 Q30 18 32 26" fill={V9Y_THEME.primaryDeep} />}
      {leaves >= 4 && <circle cx="32" cy="20" r="5" fill={V9Y_THEME.honey} />}
    </svg>
  );
}

function V9YDashboard() {
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
  const pct = (prog / goal) * 100;

  return (
    <div style={{
      background: V9Y_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V9Y_THEME.ink, paddingBottom: 24, overflow: 'hidden',
    }}>
      <ConfettiBurst show={confetti} color={V9Y_THEME.honey} accent={V9Y_THEME.primary} />

      {/* Header */}
      <div style={{ padding: '16px 20px 6px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 11, color: V9Y_THEME.inkSoft, fontWeight: 600 }}>Good morning,</div>
          <div style={{ fontFamily: V9Y_THEME.display, fontSize: 24, fontWeight: 500, lineHeight: 1.1, marginTop: 2 }}>
            Ayesha
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{
            width: 38, height: 38, borderRadius: 12,
            background: V9Y_THEME.surface, border: `1px solid ${V9Y_THEME.border}`,
            color: V9Y_THEME.ink, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="bell" size={17} />
          </button>
          <div style={{
            width: 38, height: 38, borderRadius: 12,
            background: V9Y_THEME.honey, color: V9Y_THEME.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 800, fontSize: 13,
          }}>AR</div>
        </div>
      </div>

      {/* Hero — your garden */}
      <div style={{ padding: '10px 20px 0' }}>
        <div style={{
          background: `linear-gradient(160deg, ${V9Y_THEME.cream} 0%, ${V9Y_THEME.honey}33 100%)`,
          borderRadius: 28, padding: '20px 20px 0',
          position: 'relative', overflow: 'hidden',
          border: `1px solid ${V9Y_THEME.border}`,
        }}>
          {/* Sun */}
          <div style={{ position: 'absolute', right: 18, top: 18, width: 44, height: 44 }}>
            <svg width="44" height="44" viewBox="0 0 44 44">
              <circle cx="22" cy="22" r="12" fill={V9Y_THEME.honey} />
              {[0, 45, 90, 135, 180, 225, 270, 315].map((a) => (
                <line key={a} x1="22" y1="22"
                  x2={22 + Math.cos(a * Math.PI / 180) * 20}
                  y2={22 + Math.sin(a * Math.PI / 180) * 20}
                  stroke={V9Y_THEME.honey} strokeWidth="2" strokeLinecap="round" opacity="0.85" />
              ))}
            </svg>
          </div>
          <div style={{ maxWidth: '68%' }}>
            <div style={{ fontSize: 11, color: V9Y_THEME.inkSoft, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
              Your garden
            </div>
            <div style={{
              fontFamily: V9Y_THEME.display, fontSize: 56, fontWeight: 400,
              color: V9Y_THEME.honeyDeep, lineHeight: 0.95,
              letterSpacing: '-0.02em', marginTop: 6,
              fontVariantNumeric: 'tabular-nums',
            }}>
              {useCountUp(points).toLocaleString()}
            </div>
            <div style={{ fontSize: 13, color: V9Y_THEME.inkSoft, marginTop: 6 }}>
              noor points bloomed
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 5,
              marginTop: 10, padding: '3px 9px', borderRadius: 999,
              background: V9Y_THEME.honey + '44',
              color: V9Y_THEME.honeyDeep, fontSize: 11, fontWeight: 800,
            }}>
              <Icon name="bolt" size={12} strokeWidth={2.4} />
              +127 today
            </div>
          </div>
          <div style={{
            marginTop: 14, display: 'flex', justifyContent: 'space-around',
            alignItems: 'flex-end',
            background: `linear-gradient(180deg, transparent 50%, ${V9Y_THEME.honey}22 100%)`,
            paddingBottom: 6,
          }}>
            <V9YPlant grow={1} size={50} />
            <V9YPlant grow={0.75} size={56} />
            <V9YPlant grow={0.4} size={48} />
            <V9YPlant grow={0.9} size={58} />
            <V9YPlant grow={0.2} size={42} />
          </div>
        </div>

        <button onClick={validate} disabled={validated} style={{
          marginTop: 12, width: '100%', padding: '15px 20px',
          borderRadius: 18, border: `2px solid ${V9Y_THEME.honeyDeep}`,
          background: validated ? V9Y_THEME.surface : V9Y_THEME.honeyDeep,
          color: validated ? V9Y_THEME.honeyDeep : '#fff',
          fontSize: 14, fontWeight: 700, cursor: validated ? 'default' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontFamily: V9Y_THEME.display, letterSpacing: '-0.01em',
        }}>
          {validated ? (
            <><Icon name="check" size={16} strokeWidth={2.5} />Today's harvest · sealed (+85)</>
          ) : (
            <>Harvest today's noor <Icon name="arrow" size={14} strokeWidth={2.2} /></>
          )}
        </button>
      </div>

      {/* Streak */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V9Y_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V9Y_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: V9Y_THEME.inkSoft, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
                Growing streak
              </div>
              <div style={{ fontFamily: V9Y_THEME.display, fontSize: 28, lineHeight: 1, marginTop: 4 }}>
                12 days <em style={{ fontStyle: 'italic', color: V9Y_THEME.honeyDeep, fontSize: 16 }}>· keep growing</em>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 4 }}>
            {['M','T','W','T','F','S','S'].map((l, i) => {
              const done = i < 4;
              const today = i === 4;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 10, color: V9Y_THEME.muted, fontWeight: 700 }}>{l}</span>
                  <svg width="24" height="28" viewBox="0 0 24 28">
                    <rect x="4" y="22" width="16" height="5" rx="1" fill={done ? V9Y_THEME.soil : V9Y_THEME.track} />
                    {done && (
                      <>
                        <path d="M12 22 Q12 14 12 10" stroke={V9Y_THEME.primary} strokeWidth="1.5" fill="none" />
                        <path d="M12 16 Q8 14 7 10 Q11 10 12 14" fill={V9Y_THEME.primary} />
                        <path d="M12 14 Q16 12 17 8 Q13 8 12 12" fill={V9Y_THEME.primaryDeep} />
                      </>
                    )}
                    {today && !done && (
                      <path d="M12 22 L12 18" stroke={V9Y_THEME.honeyDeep} strokeWidth="1.5" strokeLinecap="round" strokeDasharray="1.5 1.5" />
                    )}
                  </svg>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Progress sun-arc */}
      <div style={{ padding: '12px 20px 0' }}>
        <div style={{
          background: V9Y_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V9Y_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ fontFamily: V9Y_THEME.display, fontSize: 20 }}>
              <em style={{ fontStyle: 'italic' }}>Progress</em>
            </div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V9Y_THEME.track }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '4px 10px', borderRadius: 999, border: 'none',
                  background: tab === t ? V9Y_THEME.ink : 'transparent',
                  color: tab === t ? '#fff' : V9Y_THEME.inkSoft,
                  fontSize: 10, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <svg width="100" height="60" viewBox="0 0 100 60">
              <path d="M10 55 A40 40 0 0 1 90 55" fill="none" stroke={V9Y_THEME.track} strokeWidth="8" strokeLinecap="round" />
              <path d="M10 55 A40 40 0 0 1 90 55" fill="none"
                stroke={V9Y_THEME.honeyDeep} strokeWidth="8" strokeLinecap="round"
                strokeDasharray={`${(pct / 100) * 126} 200`} />
              <circle cx={10 + Math.cos(Math.PI - (pct / 100) * Math.PI) * 40 + 40}
                cy={55 - Math.sin((pct / 100) * Math.PI) * 40}
                r="6" fill={V9Y_THEME.honey} stroke={V9Y_THEME.honeyDeep} strokeWidth="2" />
            </svg>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: V9Y_THEME.display, fontSize: 30, letterSpacing: '-0.02em', lineHeight: 1 }}>
                {prog.toLocaleString()}
              </div>
              <div style={{ fontSize: 11, color: V9Y_THEME.inkSoft, marginTop: 2 }}>
                of {goal.toLocaleString()} {tab.toLowerCase()} goal
              </div>
              <div style={{ fontSize: 10, color: V9Y_THEME.honeyDeep, fontWeight: 700, marginTop: 5, letterSpacing: '0.05em', textTransform: 'uppercase' }}>
                {Math.round(pct)}% · sun is rising
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Plots */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{ fontFamily: V9Y_THEME.display, fontSize: 20, padding: '0 2px 10px' }}>
          Today's <em style={{ fontStyle: 'italic' }}>plots</em>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <V9YBed icon="book" label="Quran" sub="Al-Mulk · 2/30 pages"
            bg={V9Y_THEME.butter} fg={V9Y_THEME.ink} pts="+15" growEmoji="🌱" />
          <V9YBed icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target}`}
            bg={V9Y_THEME.honey} fg={V9Y_THEME.ink} pts={`+${dhikr.count}`} growEmoji="🌿"
            onClick={dhikr.inc} tappable />
          <V9YBed icon="hands" label="Duas" sub="3 of 5 today"
            bg={V9Y_THEME.plum} fg="#fff" pts="+30" growEmoji="🌼" />
          <V9YBed icon="users" label="Invite" sub="+100 per friend"
            bg={V9Y_THEME.primary} fg="#fff" pts="+100" growEmoji="🌷" />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V9Y_THEME.primaryDeep, color: '#fff',
          borderRadius: 24, padding: 18, position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', right: 10, top: 10 }}>
            <svg width="70" height="90" viewBox="0 0 70 90">
              <rect x="32" y="55" width="6" height="35" fill={V9Y_THEME.soil} />
              <g fill={V9Y_THEME.primary}>
                <path d="M35 55 Q10 40 5 30 Q20 32 35 48 Z" />
                <path d="M35 55 Q60 40 65 30 Q50 32 35 48 Z" />
                <path d="M35 50 Q15 25 10 15 Q25 18 35 42 Z" />
                <path d="M35 50 Q55 25 60 15 Q45 18 35 42 Z" />
              </g>
              <circle cx="32" cy="52" r="2" fill={V9Y_THEME.honeyDeep} />
              <circle cx="38" cy="54" r="2" fill={V9Y_THEME.honeyDeep} />
              <circle cx="35" cy="49" r="2" fill={V9Y_THEME.honey} />
            </svg>
          </div>
          <div style={{ maxWidth: '62%' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: V9Y_THEME.honey, fontWeight: 700 }}>
              Plant a date tree
            </div>
            <div style={{ fontFamily: V9Y_THEME.display, fontSize: 22, marginTop: 6, lineHeight: 1.15 }}>
              Feed <em style={{ fontStyle: 'italic', color: V9Y_THEME.honey }}>120 families</em> in Yemen
            </div>
            <div style={{ fontSize: 11, opacity: 0.8, marginTop: 4 }}>
              100 pts = 1 day of water for a family
            </div>
          </div>
          <div style={{ marginTop: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, opacity: 0.85 }}>
              <span>7,420 / 10,000 pts</span>
              <span>74%</span>
            </div>
            <div style={{ marginTop: 6, height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.15)' }}>
              <div style={{
                height: '100%', width: '74%', borderRadius: 999,
                background: `linear-gradient(90deg, ${V9Y_THEME.honey}, ${V9Y_THEME.butter})`,
              }} />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
            {[50, 100, 250].map((v) => (
              <button key={v} style={{
                flex: 1, padding: '9px 0', borderRadius: 999,
                background: 'transparent', border: '1.5px solid rgba(255,255,255,0.25)',
                color: '#fff', fontSize: 11, fontWeight: 600,
                cursor: 'pointer', fontFamily: 'inherit',
              }}>{v} pts</button>
            ))}
            <button style={{
              flex: 1.4, padding: '9px 0', borderRadius: 999,
              background: V9Y_THEME.honey, border: 'none', color: V9Y_THEME.primaryDeep,
              fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
            }}>Plant →</button>
          </div>
        </div>
      </div>
    </div>
  );
}

function V9YBed({ icon, label, sub, bg, fg, pts, growEmoji, onClick, tappable }) {
  return (
    <button onClick={onClick} style={{
      background: bg, color: fg, borderRadius: 22, padding: 14,
      border: 'none', textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', position: 'relative', overflow: 'hidden',
      minHeight: 120,
    }}>
      <div style={{ position: 'absolute', right: 10, top: 10, fontSize: 22 }}>{growEmoji}</div>
      <div style={{
        width: 30, height: 30, borderRadius: 10,
        background: 'rgba(255,255,255,0.4)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={16} strokeWidth={2} />
      </div>
      <div style={{ marginTop: 30 }}>
        <div style={{ fontSize: 14, fontWeight: 800, letterSpacing: '-0.01em' }}>{label}</div>
        <div style={{ fontSize: 11, opacity: 0.8, marginTop: 2 }}>{sub}</div>
        <div style={{
          display: 'inline-flex', marginTop: 8,
          fontSize: 10, fontWeight: 800, padding: '3px 7px',
          borderRadius: 999, background: 'rgba(255,255,255,0.45)',
        }}>{pts}{tappable && ' · TAP'}</div>
      </div>
    </button>
  );
}

Object.assign(window, { V9YDashboard });
