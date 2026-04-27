// V9Y2 — Garden · NEON YELLOW (#f9f506) + sage
// Crisp neon yellow blooms in a sage garden. Clean, modern, high-contrast.

const V9Y2_THEME = {
  bg: '#FCFAEA',                // pale cream
  surface: '#FFFFFF',
  cream: '#FFFDEE',
  ink: '#1A1F0F',
  inkSoft: '#5C6645',
  muted: '#A8B093',
  primary: '#3F6A48',           // sage
  primaryDeep: '#243F2A',
  neon: '#F9F506',              // neon yellow (highlight)
  neonDeep: '#7A7700',          // regular muted shade
  neonSoft: '#FFFBA8',          // regular soft shade
  butter: '#FFFBA8',
  plum: '#3F6A48',
  soil: '#5A4028',
  border: 'rgba(26,31,15,0.1)',
  track: '#F0EDC8',
  display: '"Fraunces", "Instrument Serif", Georgia, serif',
};

function V9Y2Plant({ grow = 0.5, size = 64, bloom = false }) {
  const leaves = Math.ceil(grow * 4);
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <path d="M16 48 L48 48 L44 60 L20 60 Z" fill={V9Y2_THEME.soil} />
      <ellipse cx="32" cy="48" rx="16" ry="3" fill="#3D2A1A" />
      <path d={`M32 48 Q32 ${48 - grow * 30} 32 ${30 - grow * 10}`} stroke={V9Y2_THEME.primary} strokeWidth="2" fill="none" strokeLinecap="round" />
      {leaves >= 1 && <path d="M32 40 Q24 36 22 30 Q28 30 32 38" fill={V9Y2_THEME.primary} />}
      {leaves >= 2 && <path d="M32 36 Q40 32 42 26 Q36 26 32 34" fill={V9Y2_THEME.primary} />}
      {leaves >= 3 && <path d="M32 28 Q26 24 24 18 Q30 18 32 26" fill={V9Y2_THEME.primaryDeep} />}
      {leaves >= 4 && bloom && (
        <g>
          <circle cx="32" cy="20" r="6" fill={V9Y2_THEME.neon} stroke={V9Y2_THEME.neonDeep} strokeWidth="1" />
          <circle cx="32" cy="20" r="2" fill={V9Y2_THEME.neonDeep} />
        </g>
      )}
      {leaves >= 4 && !bloom && <circle cx="32" cy="20" r="5" fill={V9Y2_THEME.neonSoft} />}
    </svg>
  );
}

function V9Y2Dashboard() {
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
      background: V9Y2_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V9Y2_THEME.ink, paddingBottom: 24, overflow: 'hidden',
    }}>
      <ConfettiBurst show={confetti} color={V9Y2_THEME.neon} accent={V9Y2_THEME.primary} />

      {/* Header */}
      <div style={{ padding: '16px 20px 6px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 11, color: V9Y2_THEME.inkSoft, fontWeight: 600 }}>Good morning,</div>
          <div style={{ fontFamily: V9Y2_THEME.display, fontSize: 24, lineHeight: 1.1, marginTop: 2 }}>Ayesha</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{
            width: 38, height: 38, borderRadius: 12,
            background: V9Y2_THEME.surface, border: `1px solid ${V9Y2_THEME.border}`,
            color: V9Y2_THEME.ink, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="bell" size={17} />
          </button>
          <div style={{
            width: 38, height: 38, borderRadius: 12,
            background: V9Y2_THEME.neon, color: V9Y2_THEME.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 800, fontSize: 13,
            border: `1px solid ${V9Y2_THEME.neonDeep}33`,
          }}>AR</div>
        </div>
      </div>

      {/* Hero — sage garden with neon blooms */}
      <div style={{ padding: '10px 20px 0' }}>
        <div style={{
          background: V9Y2_THEME.primary, color: '#fff',
          borderRadius: 28, padding: '20px 20px 0',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* Neon sun */}
          <div style={{ position: 'absolute', right: 18, top: 18, width: 48, height: 48 }}>
            <svg width="48" height="48" viewBox="0 0 48 48">
              <circle cx="24" cy="24" r="13" fill={V9Y2_THEME.neon} />
              {[0, 45, 90, 135, 180, 225, 270, 315].map((a) => (
                <line key={a} x1="24" y1="24"
                  x2={24 + Math.cos(a * Math.PI / 180) * 22}
                  y2={24 + Math.sin(a * Math.PI / 180) * 22}
                  stroke={V9Y2_THEME.neon} strokeWidth="2.2" strokeLinecap="round" opacity="0.9" />
              ))}
            </svg>
          </div>
          <div style={{ maxWidth: '68%' }}>
            <div style={{ fontSize: 11, color: V9Y2_THEME.neon, fontWeight: 800, letterSpacing: '0.12em', textTransform: 'uppercase' }}>
              Your garden
            </div>
            <div style={{
              fontFamily: V9Y2_THEME.display, fontSize: 56, fontWeight: 400,
              color: V9Y2_THEME.neon, lineHeight: 0.95,
              letterSpacing: '-0.02em', marginTop: 6,
              fontVariantNumeric: 'tabular-nums',
              textShadow: `0 0 24px ${V9Y2_THEME.neon}55`,
            }}>
              {useCountUp(points).toLocaleString()}
            </div>
            <div style={{ fontSize: 13, opacity: 0.85, marginTop: 6 }}>
              noor points bloomed
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 5,
              marginTop: 10, padding: '4px 10px', borderRadius: 999,
              background: V9Y2_THEME.neon,
              color: V9Y2_THEME.ink, fontSize: 11, fontWeight: 800,
            }}>
              <Icon name="bolt" size={12} strokeWidth={2.4} />
              +127 today
            </div>
          </div>
          <div style={{
            marginTop: 14, display: 'flex', justifyContent: 'space-around',
            alignItems: 'flex-end',
            background: `linear-gradient(180deg, transparent 50%, ${V9Y2_THEME.primaryDeep}88 100%)`,
            paddingBottom: 6,
          }}>
            <V9Y2Plant grow={1} size={50} bloom />
            <V9Y2Plant grow={0.75} size={56} bloom />
            <V9Y2Plant grow={0.4} size={48} />
            <V9Y2Plant grow={0.9} size={58} bloom />
            <V9Y2Plant grow={0.2} size={42} />
          </div>
        </div>

        <button onClick={validate} disabled={validated} style={{
          marginTop: 12, width: '100%', padding: '15px 20px',
          borderRadius: 18, border: `2px solid ${V9Y2_THEME.ink}`,
          background: validated ? V9Y2_THEME.surface : V9Y2_THEME.neon,
          color: V9Y2_THEME.ink,
          fontSize: 14, fontWeight: 800, cursor: validated ? 'default' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontFamily: V9Y2_THEME.display, letterSpacing: '-0.01em',
        }}>
          {validated ? (
            <><Icon name="check" size={16} strokeWidth={2.5} />Today's harvest · sealed (+85)</>
          ) : (
            <>Harvest today's noor <Icon name="arrow" size={14} strokeWidth={2.4} /></>
          )}
        </button>
      </div>

      {/* Streak */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V9Y2_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V9Y2_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: V9Y2_THEME.inkSoft, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
                Growing streak
              </div>
              <div style={{ fontFamily: V9Y2_THEME.display, fontSize: 28, lineHeight: 1, marginTop: 4 }}>
                12 days <em style={{ fontStyle: 'italic', color: V9Y2_THEME.primary, fontSize: 16 }}>· keep growing</em>
              </div>
            </div>
            <div style={{
              padding: '5px 9px', borderRadius: 999,
              background: V9Y2_THEME.neon, color: V9Y2_THEME.ink,
              fontSize: 10, fontWeight: 800, letterSpacing: '0.08em', textTransform: 'uppercase',
            }}>Best 28</div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 4 }}>
            {['M','T','W','T','F','S','S'].map((l, i) => {
              const done = i < 4;
              const today = i === 4;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 10, color: V9Y2_THEME.muted, fontWeight: 700 }}>{l}</span>
                  <svg width="24" height="28" viewBox="0 0 24 28">
                    <rect x="4" y="22" width="16" height="5" rx="1" fill={done ? V9Y2_THEME.soil : V9Y2_THEME.track} />
                    {done && (
                      <>
                        <path d="M12 22 Q12 14 12 10" stroke={V9Y2_THEME.primary} strokeWidth="1.5" fill="none" />
                        <path d="M12 16 Q8 14 7 10 Q11 10 12 14" fill={V9Y2_THEME.primary} />
                        <path d="M12 14 Q16 12 17 8 Q13 8 12 12" fill={V9Y2_THEME.primaryDeep} />
                        <circle cx="12" cy="7" r="2.5" fill={V9Y2_THEME.neon} />
                      </>
                    )}
                    {today && !done && (
                      <path d="M12 22 L12 18" stroke={V9Y2_THEME.neonDeep} strokeWidth="1.5" strokeLinecap="round" strokeDasharray="1.5 1.5" />
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
          background: V9Y2_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V9Y2_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ fontFamily: V9Y2_THEME.display, fontSize: 20 }}>
              <em style={{ fontStyle: 'italic' }}>Progress</em>
            </div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V9Y2_THEME.track }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '4px 10px', borderRadius: 999, border: 'none',
                  background: tab === t ? V9Y2_THEME.ink : 'transparent',
                  color: tab === t ? V9Y2_THEME.neon : V9Y2_THEME.inkSoft,
                  fontSize: 10, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <svg width="100" height="60" viewBox="0 0 100 60">
              <path d="M10 55 A40 40 0 0 1 90 55" fill="none" stroke={V9Y2_THEME.track} strokeWidth="8" strokeLinecap="round" />
              <path d="M10 55 A40 40 0 0 1 90 55" fill="none"
                stroke={V9Y2_THEME.neon} strokeWidth="8" strokeLinecap="round"
                strokeDasharray={`${(pct / 100) * 126} 200`} />
              <circle cx={10 + Math.cos(Math.PI - (pct / 100) * Math.PI) * 40 + 40}
                cy={55 - Math.sin((pct / 100) * Math.PI) * 40}
                r="6" fill={V9Y2_THEME.neon} stroke={V9Y2_THEME.ink} strokeWidth="2" />
            </svg>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: V9Y2_THEME.display, fontSize: 30, letterSpacing: '-0.02em', lineHeight: 1 }}>
                {prog.toLocaleString()}
              </div>
              <div style={{ fontSize: 11, color: V9Y2_THEME.inkSoft, marginTop: 2 }}>
                of {goal.toLocaleString()} {tab.toLowerCase()} goal
              </div>
              <div style={{
                display: 'inline-block', marginTop: 6,
                padding: '2px 8px', borderRadius: 999,
                background: V9Y2_THEME.neon, color: V9Y2_THEME.ink,
                fontSize: 10, fontWeight: 800, letterSpacing: '0.05em', textTransform: 'uppercase',
              }}>{Math.round(pct)}% · sun rising</div>
            </div>
          </div>
        </div>
      </div>

      {/* Plots */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{ fontFamily: V9Y2_THEME.display, fontSize: 20, padding: '0 2px 10px' }}>
          Today's <em style={{ fontStyle: 'italic' }}>plots</em>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <V9Y2Bed icon="book" label="Quran" sub="Al-Mulk · 2/30 pages"
            bg={V9Y2_THEME.cream} fg={V9Y2_THEME.ink} border={V9Y2_THEME.border} pts="+15" growEmoji="🌱" />
          <V9Y2Bed icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target}`}
            bg={V9Y2_THEME.neon} fg={V9Y2_THEME.ink} pts={`+${dhikr.count}`} growEmoji="🌿"
            onClick={dhikr.inc} tappable />
          <V9Y2Bed icon="hands" label="Duas" sub="3 of 5 today"
            bg={V9Y2_THEME.neonSoft} fg={V9Y2_THEME.ink} pts="+30" growEmoji="🌼" />
          <V9Y2Bed icon="users" label="Invite" sub="+100 per friend"
            bg={V9Y2_THEME.primary} fg="#fff" pts="+100" growEmoji="🌷" />
        </div>
      </div>

      {/* Donation — neon panel */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V9Y2_THEME.ink, color: '#fff',
          borderRadius: 24, padding: 18, position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', right: 10, top: 10 }}>
            <svg width="70" height="90" viewBox="0 0 70 90">
              <rect x="32" y="55" width="6" height="35" fill={V9Y2_THEME.soil} />
              <g fill={V9Y2_THEME.primary}>
                <path d="M35 55 Q10 40 5 30 Q20 32 35 48 Z" />
                <path d="M35 55 Q60 40 65 30 Q50 32 35 48 Z" />
                <path d="M35 50 Q15 25 10 15 Q25 18 35 42 Z" />
                <path d="M35 50 Q55 25 60 15 Q45 18 35 42 Z" />
              </g>
              <circle cx="32" cy="52" r="2.5" fill={V9Y2_THEME.neon} />
              <circle cx="38" cy="54" r="2.5" fill={V9Y2_THEME.neon} />
              <circle cx="35" cy="49" r="2.5" fill={V9Y2_THEME.neon} />
            </svg>
          </div>
          <div style={{ maxWidth: '62%' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: V9Y2_THEME.neon, fontWeight: 800 }}>
              Plant a date tree
            </div>
            <div style={{ fontFamily: V9Y2_THEME.display, fontSize: 22, marginTop: 6, lineHeight: 1.15 }}>
              Feed <em style={{ fontStyle: 'italic', color: V9Y2_THEME.neon }}>120 families</em> in Yemen
            </div>
            <div style={{ fontSize: 11, opacity: 0.75, marginTop: 4 }}>
              100 pts = 1 day of water for a family
            </div>
          </div>
          <div style={{ marginTop: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, opacity: 0.85 }}>
              <span>7,420 / 10,000 pts</span>
              <span style={{ color: V9Y2_THEME.neon, fontWeight: 800 }}>74%</span>
            </div>
            <div style={{ marginTop: 6, height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.15)' }}>
              <div style={{
                height: '100%', width: '74%', borderRadius: 999,
                background: V9Y2_THEME.neon,
                boxShadow: `0 0 10px ${V9Y2_THEME.neon}88`,
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
              background: V9Y2_THEME.neon, border: 'none', color: V9Y2_THEME.ink,
              fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
            }}>Plant →</button>
          </div>
        </div>
      </div>
    </div>
  );
}

function V9Y2Bed({ icon, label, sub, bg, fg, border, pts, growEmoji, onClick, tappable }) {
  return (
    <button onClick={onClick} style={{
      background: bg, color: fg, borderRadius: 22, padding: 14,
      border: border ? `1px solid ${border}` : 'none',
      textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', position: 'relative', overflow: 'hidden',
      minHeight: 120,
    }}>
      <div style={{ position: 'absolute', right: 10, top: 10, fontSize: 22 }}>{growEmoji}</div>
      <div style={{
        width: 30, height: 30, borderRadius: 10,
        background: 'rgba(255,255,255,0.45)',
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
          borderRadius: 999, background: 'rgba(255,255,255,0.5)',
        }}>{pts}{tappable && ' · TAP'}</div>
      </div>
    </button>
  );
}

Object.assign(window, { V9Y2Dashboard });
