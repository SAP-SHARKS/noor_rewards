// V6 — Card Stack / Sky Blue
// Soft sky-blue surface, playful rounded everything, friendly illustration feel.
// Horizontally-scrollable "today's missions" card stack.

const V6_THEME = {
  bg: '#DCE9FA',
  surface: '#FFFFFF',
  cream: '#FFFDF7',
  ink: '#13224A',
  inkSoft: '#5B6A8C',
  muted: '#A0AAC3',
  primary: '#4A7FE3',        // friendly sky blue
  primaryDeep: '#1F4BB8',
  sky: '#A6C8FF',
  mint: '#8CE1C8',
  coin: '#FFD266',
  coral: '#FF9A8B',
  plum: '#B794F0',
  border: 'rgba(19,34,74,0.08)',
  track: '#E4EBF7',
  pillTrack: '#E4EBF7',
  pillOn: '#13224A',
  pillOnText: '#FFFFFF',
  pillText: '#5B6A8C',
};

function V6Dashboard() {
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

  return (
    <div style={{
      background: V6_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V6_THEME.ink, paddingBottom: 24, overflow: 'hidden',
    }}>
      <ConfettiBurst show={confetti} color={V6_THEME.coin} accent={V6_THEME.primary} />

      {/* cloudy decorative top */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 280,
        background: `radial-gradient(ellipse at 20% 20%, rgba(255,255,255,0.6), transparent 40%), radial-gradient(ellipse at 80% 30%, rgba(255,255,255,0.5), transparent 45%)`,
        pointerEvents: 'none',
      }} />

      {/* Header */}
      <div style={{
        position: 'relative', padding: '16px 20px 6px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 42, height: 42, borderRadius: '50%',
            background: `linear-gradient(135deg, ${V6_THEME.coral}, ${V6_THEME.coin})`,
            color: '#fff', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 15,
            border: '3px solid #fff',
            boxShadow: '0 3px 8px rgba(19,34,74,0.1)',
          }}>AR</div>
          <div>
            <div style={{ fontSize: 12, color: V6_THEME.inkSoft, fontWeight: 600 }}>Hey, Ayesha 👋</div>
            <div style={{ fontSize: 14, fontWeight: 700 }}>Let's earn some light today</div>
          </div>
        </div>
        <button style={{
          width: 40, height: 40, borderRadius: '50%', border: 'none',
          background: V6_THEME.surface, color: V6_THEME.ink, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 2px 6px rgba(19,34,74,0.08)', position: 'relative',
        }}>
          <Icon name="bell" size={18} />
          <span style={{
            position: 'absolute', top: 8, right: 9, width: 8, height: 8,
            borderRadius: '50%', background: V6_THEME.coral,
            border: `2px solid ${V6_THEME.surface}`,
          }} />
        </button>
      </div>

      {/* Points card with illustration */}
      <div style={{ position: 'relative', padding: '10px 20px 0' }}>
        <div style={{
          background: V6_THEME.surface, borderRadius: 28, padding: 20,
          position: 'relative', overflow: 'hidden',
          boxShadow: '0 6px 20px rgba(19,34,74,0.08)',
        }}>
          {/* illustration */}
          <div style={{ position: 'absolute', right: -8, top: 8 }}>
            <V6Illustration />
          </div>

          <div style={{ position: 'relative', width: '65%' }}>
            <div style={{ fontSize: 11, color: V6_THEME.inkSoft, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em' }}>
              Your points
            </div>
            <div style={{
              fontSize: 46, fontWeight: 800, letterSpacing: '-0.03em',
              lineHeight: 1, marginTop: 6, color: V6_THEME.primaryDeep,
              fontVariantNumeric: 'tabular-nums',
            }}>
              {useCountUp(points).toLocaleString()}
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              padding: '3px 9px', borderRadius: 999,
              background: V6_THEME.mint + '66', color: '#0D5A44',
              fontSize: 11, fontWeight: 700, marginTop: 8,
            }}>
              <Icon name="bolt" size={12} strokeWidth={2.4} />
              +127 today
            </div>
          </div>

          <button onClick={validate} disabled={validated} style={{
            marginTop: 18, width: '100%', padding: '14px 20px',
            borderRadius: 18, border: 'none',
            background: validated ? V6_THEME.mint : V6_THEME.primary,
            color: '#fff',
            fontSize: 14, fontWeight: 800, cursor: validated ? 'default' : 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            fontFamily: 'inherit',
            boxShadow: validated ? 'none' : `0 5px 0 ${V6_THEME.primaryDeep}, 0 10px 20px rgba(74,127,227,0.3)`,
            transform: validated ? 'translateY(3px)' : 'none',
            transition: 'all .15s',
          }}>
            {validated ? (
              <><Icon name="check" size={18} strokeWidth={3} />Points validated · +85</>
            ) : (
              <><Icon name="sparkle" size={16} />Validate today's points</>
            )}
          </button>
        </div>
      </div>

      {/* Streak row — floating pill */}
      <div style={{ position: 'relative', padding: '14px 20px 0' }}>
        <div style={{
          background: V6_THEME.ink, color: '#fff',
          borderRadius: 22, padding: '14px 16px',
          display: 'flex', alignItems: 'center', gap: 14,
          boxShadow: '0 6px 16px rgba(19,34,74,0.2)',
        }}>
          <div style={{
            width: 46, height: 46, borderRadius: '50%',
            background: V6_THEME.coin, color: V6_THEME.ink,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <Icon name="flame" size={22} strokeWidth={2.2} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 700 }}>
              12-day streak! Keep it going
            </div>
            <div style={{ display: 'flex', gap: 3, marginTop: 6 }}>
              {[1,1,1,1,0,0,0].map((d, i) => (
                <span key={i} style={{
                  flex: 1, height: 5, borderRadius: 999,
                  background: d ? V6_THEME.coin : 'rgba(255,255,255,0.2)',
                }} />
              ))}
            </div>
          </div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', fontWeight: 600 }}>
            Best<br /><span style={{ color: '#fff', fontSize: 14, fontWeight: 800 }}>28d</span>
          </div>
        </div>
      </div>

      {/* Progress — simple with tabs */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{
          background: V6_THEME.surface, borderRadius: 22, padding: 16,
          boxShadow: '0 3px 10px rgba(19,34,74,0.05)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ fontSize: 14, fontWeight: 800 }}>Progress</div>
            <div style={{ display: 'flex', gap: 2, padding: 3, borderRadius: 999, background: V6_THEME.track }}>
              {['Today', 'Week', 'Month'].map((t) => (
                <button key={t} onClick={() => setTab(t)} style={{
                  padding: '4px 10px', borderRadius: 999, border: 'none',
                  background: tab === t ? V6_THEME.surface : 'transparent',
                  color: tab === t ? V6_THEME.ink : V6_THEME.inkSoft,
                  fontSize: 11, fontWeight: 700, cursor: 'pointer',
                  fontFamily: 'inherit',
                  boxShadow: tab === t ? '0 1px 3px rgba(0,0,0,0.06)' : 'none',
                }}>{t}</button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ fontSize: 32, fontWeight: 800, letterSpacing: '-0.03em', color: V6_THEME.primary }}>
              {prog.toLocaleString()}
            </span>
            <span style={{ fontSize: 12, color: V6_THEME.inkSoft }}>/ {goal.toLocaleString()}</span>
          </div>
          <div style={{
            marginTop: 10, height: 14, borderRadius: 999,
            background: V6_THEME.track, overflow: 'hidden', position: 'relative',
          }}>
            <div style={{
              height: '100%', width: `${(prog / goal) * 100}%`,
              background: `linear-gradient(90deg, ${V6_THEME.primary}, ${V6_THEME.sky})`,
              borderRadius: 999,
              position: 'relative', overflow: 'hidden',
            }}>
              <div style={{
                position: 'absolute', inset: 0,
                background: 'linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.4) 50%, transparent 100%)',
                backgroundSize: '200% 100%',
                animation: 'v6-shimmer 2s infinite',
              }} />
            </div>
          </div>
          <style>{`@keyframes v6-shimmer{0%{background-position:-100% 0}100%{background-position:100% 0}}`}</style>
        </div>
      </div>

      {/* Missions card stack — horizontal scroll */}
      <div style={{ padding: '18px 0 0' }}>
        <div style={{
          padding: '0 20px 10px',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div style={{ fontSize: 15, fontWeight: 800 }}>Today's missions</div>
          <div style={{ fontSize: 12, color: V6_THEME.primary, fontWeight: 700 }}>See all</div>
        </div>
        <div style={{
          display: 'flex', gap: 12, padding: '0 20px 6px',
          overflowX: 'auto', scrollbarWidth: 'none',
        }}>
          <V6Mission
            icon="book" label="Read Quran" sub="2 pages" pts="+30"
            bg={V6_THEME.primary} accent={V6_THEME.sky} illus="quran"
          />
          <V6Mission
            icon="beads"
            label="Dhikr"
            sub={`${dhikr.count} / ${dhikr.target}`}
            pts={`+${dhikr.count}`}
            bg={V6_THEME.coin}
            accent="#FFE8A6"
            fg={V6_THEME.ink}
            illus="beads"
            onClick={dhikr.inc}
            tappable
          />
          <V6Mission
            icon="hands" label="5 Duas" sub="3/5 today" pts="+50"
            bg={V6_THEME.coral} accent="#FFD3CC" illus="hands"
          />
          <V6Mission
            icon="users" label="Invite" sub="+100 / friend" pts="+100"
            bg={V6_THEME.plum} accent="#E4D6FF" illus="users"
          />
        </div>
      </div>

      {/* Donation card */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V6_THEME.cream, borderRadius: 24, overflow: 'hidden',
          border: `1px solid ${V6_THEME.border}`, position: 'relative',
        }}>
          <div style={{ padding: '16px 16px 0', display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <div style={{
              width: 52, height: 52, borderRadius: 16, flexShrink: 0,
              background: `linear-gradient(135deg, ${V6_THEME.coral}, #E34F7A)`,
              color: '#fff', display: 'flex',
              alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="heart" size={24} strokeWidth={2} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.1em', color: V6_THEME.inkSoft, fontWeight: 700 }}>This week's cause</div>
              <div style={{ fontSize: 14, fontWeight: 800, marginTop: 2, lineHeight: 1.3 }}>
                Clean water · 120 families
              </div>
              <div style={{ fontSize: 11, color: V6_THEME.inkSoft, marginTop: 2 }}>
                100 pts = 1 day of water
              </div>
            </div>
          </div>
          <div style={{ padding: '12px 16px 0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, fontWeight: 700 }}>
              <span>7,420 / 10,000 pts raised</span>
              <span style={{ color: V6_THEME.coral }}>74%</span>
            </div>
            <div style={{ marginTop: 6, height: 8, borderRadius: 999, background: V6_THEME.track }}>
              <div style={{
                height: '100%', width: '74%', borderRadius: 999,
                background: `linear-gradient(90deg, ${V6_THEME.coral}, ${V6_THEME.coin})`,
              }} />
            </div>
          </div>
          <div style={{ padding: 16, display: 'flex', gap: 8 }}>
            {[50, 100, 250].map((v) => (
              <button key={v} style={{
                flex: 1, padding: '10px 0', borderRadius: 999,
                background: V6_THEME.surface, border: `1.5px solid ${V6_THEME.border}`,
                color: V6_THEME.ink, fontSize: 12, fontWeight: 700,
                cursor: 'pointer', fontFamily: 'inherit',
              }}>{v} pts</button>
            ))}
            <button style={{
              flex: 1.2, padding: '10px 0', borderRadius: 999,
              background: V6_THEME.ink, border: 'none', color: '#fff',
              fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
            }}>Donate →</button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Simple mosque/skyline illustration in the hero
function V6Illustration() {
  return (
    <svg width="130" height="120" viewBox="0 0 130 120">
      {/* sky */}
      <circle cx="98" cy="26" r="14" fill={V6_THEME.coin} opacity="0.9" />
      {/* crescent overlay on sun to make it a crescent */}
      <circle cx="104" cy="22" r="12" fill={V6_THEME.surface} />
      {/* cloud */}
      <ellipse cx="78" cy="50" rx="18" ry="8" fill={V6_THEME.sky} opacity="0.5" />
      <ellipse cx="90" cy="48" rx="14" ry="7" fill={V6_THEME.sky} opacity="0.5" />
      {/* mosque */}
      <g transform="translate(38,50)">
        <rect x="10" y="28" width="60" height="38" rx="3" fill={V6_THEME.primary} />
        <path d="M10 28 L40 10 L70 28 Z" fill={V6_THEME.primaryDeep} />
        <circle cx="40" cy="22" r="10" fill={V6_THEME.primaryDeep} />
        <rect x="18" y="38" width="10" height="14" rx="5" fill={V6_THEME.sky} />
        <rect x="35" y="38" width="10" height="14" rx="5" fill={V6_THEME.sky} />
        <rect x="52" y="38" width="10" height="14" rx="5" fill={V6_THEME.sky} />
        {/* minarets */}
        <rect x="3" y="24" width="5" height="42" fill={V6_THEME.primaryDeep} />
        <circle cx="5.5" cy="22" r="4" fill={V6_THEME.primaryDeep} />
        <rect x="72" y="24" width="5" height="42" fill={V6_THEME.primaryDeep} />
        <circle cx="74.5" cy="22" r="4" fill={V6_THEME.primaryDeep} />
      </g>
    </svg>
  );
}

function V6Mission({ icon, label, sub, pts, bg, accent, fg = '#fff', illus, onClick, tappable }) {
  return (
    <button onClick={onClick} style={{
      background: bg, color: fg,
      borderRadius: 22, padding: 14, minWidth: 150, flexShrink: 0,
      border: 'none', textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', position: 'relative', overflow: 'hidden',
      boxShadow: '0 4px 12px rgba(19,34,74,0.1)',
    }}>
      {/* accent blob */}
      <div style={{
        position: 'absolute', right: -16, bottom: -16,
        width: 70, height: 70, borderRadius: '50%',
        background: accent, opacity: 0.5,
      }} />
      <div style={{ position: 'relative' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{
            width: 34, height: 34, borderRadius: 12,
            background: 'rgba(255,255,255,0.22)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name={icon} size={18} strokeWidth={2} />
          </div>
          <span style={{
            fontSize: 11, fontWeight: 800,
            padding: '3px 8px', borderRadius: 999,
            background: 'rgba(255,255,255,0.22)',
          }}>{pts}</span>
        </div>
        <div style={{ marginTop: 36 }}>
          <div style={{ fontSize: 15, fontWeight: 800, letterSpacing: '-0.01em' }}>{label}</div>
          <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>{sub}</div>
          {tappable && (
            <div style={{
              display: 'inline-block', marginTop: 8, fontSize: 10, fontWeight: 800,
              padding: '3px 7px', borderRadius: 999,
              background: 'rgba(0,0,0,0.15)',
            }}>TAP TO COUNT</div>
          )}
        </div>
      </div>
    </button>
  );
}

Object.assign(window, { V6Dashboard });
