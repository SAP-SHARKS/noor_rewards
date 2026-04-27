// V4 — Macadam-inspired "Coin Wallet"
// Cobalt blue hero, coin-stack hero number, big Validate ritual, mascot moon.
// References Macadam's tall circular coin column, bright cobalt, white cards.

const V4_THEME = {
  bg: '#EEF3FB',
  surface: '#FFFFFF',
  ink: '#0B1A3B',
  inkSoft: '#4F5D7F',
  muted: '#9AA4BE',
  primary: '#2757E6',        // cobalt
  primaryDeep: '#0D2F91',
  sky: '#7FB1FF',
  mint: '#3DD9B6',
  coin: '#FFC233',
  coinDark: '#E5A400',
  coral: '#FF7A6C',
  lilac: '#9E7BFF',
  border: 'rgba(11,26,59,0.08)',
  track: '#E2EAF7',
  pillTrack: '#E2EAF7',
  pillOn: '#0B1A3B',
  pillOnText: '#FFFFFF',
  pillText: '#4F5D7F',
};

// Stacked coin — front/side layers with crescent engraved
function Coin({ size = 60, offset = 0 }) {
  return (
    <div style={{
      position: 'relative', width: size, height: size * 0.3,
      marginTop: offset,
    }}>
      {/* shadow base */}
      <div style={{
        position: 'absolute', inset: 0,
        borderRadius: '50%', background: V4_THEME.coinDark,
        transform: 'translateY(6px) scaleY(0.4)', filter: 'blur(1px)', opacity: 0.3,
      }} />
      {/* side rim */}
      <div style={{
        position: 'absolute', left: 0, right: 0, top: size * 0.08, height: size * 0.22,
        background: V4_THEME.coinDark, borderRadius: size,
      }} />
      {/* top face */}
      <div style={{
        position: 'absolute', left: 0, right: 0, top: 0,
        height: size * 0.3,
        background: `radial-gradient(ellipse at 35% 30%, #FFE08A 0%, ${V4_THEME.coin} 55%, ${V4_THEME.coinDark} 100%)`,
        borderRadius: '50%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width={size * 0.18} height={size * 0.18} viewBox="0 0 24 24" fill="none">
          <path d="M19 14.8A8 8 0 1 1 9.2 5a6.5 6.5 0 0 0 9.8 9.8z" stroke={V4_THEME.coinDark} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </div>
  );
}

function V4Dashboard() {
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
      background: V4_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V4_THEME.ink, paddingBottom: 24,
    }}>
      <ConfettiBurst show={confetti} color={V4_THEME.coin} accent={V4_THEME.mint} />

      {/* Header */}
      <div style={{
        padding: '16px 20px 10px', display: 'flex',
        alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 14,
            background: `linear-gradient(135deg, ${V4_THEME.primary}, ${V4_THEME.lilac})`,
            color: '#fff', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            fontWeight: 800, fontSize: 14,
          }}>AR</div>
          <div>
            <div style={{ fontSize: 11, color: V4_THEME.inkSoft, fontWeight: 600 }}>Salam, Ayesha</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13, fontWeight: 700 }}>
              Level 7 · Munir
              <span style={{
                fontSize: 9, fontWeight: 800, padding: '2px 6px',
                borderRadius: 999, background: V4_THEME.mint, color: '#0A3B2E',
              }}>PRO</span>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={v4IconBtn()}><Icon name="calendar" size={18} /></button>
          <button style={v4IconBtn()}><Icon name="bell" size={18} /></button>
        </div>
      </div>

      {/* Hero — cobalt card, coin stack, giant points */}
      <div style={{ padding: '6px 20px 0' }}>
        <div style={{
          background: `linear-gradient(160deg, ${V4_THEME.primary} 0%, ${V4_THEME.primaryDeep} 100%)`,
          borderRadius: 28, padding: '22px 22px 20px',
          color: '#fff', position: 'relative', overflow: 'hidden',
          boxShadow: '0 10px 28px rgba(13,47,145,0.3)',
        }}>
          {/* decorative dotted grid */}
          <div style={{
            position: 'absolute', inset: 0,
            backgroundImage: `radial-gradient(rgba(255,255,255,0.12) 1px, transparent 1px)`,
            backgroundSize: '14px 14px', pointerEvents: 'none',
          }} />
          {/* mascot — crescent moon character */}
          <div style={{ position: 'absolute', top: 14, right: 16 }}>
            <svg width="80" height="80" viewBox="0 0 80 80">
              <defs>
                <radialGradient id="v4moon" cx="35%" cy="35%">
                  <stop offset="0%" stopColor="#FFF" />
                  <stop offset="100%" stopColor={V4_THEME.sky} />
                </radialGradient>
              </defs>
              <path d="M55 40a20 20 0 1 1-16-19.5 16 16 0 0 0 16 19.5z" fill="url(#v4moon)" />
              <circle cx="44" cy="38" r="2.2" fill={V4_THEME.primaryDeep} />
              <circle cx="52" cy="38" r="2.2" fill={V4_THEME.primaryDeep} />
              <path d="M45 46c2 2 5 2 7 0" stroke={V4_THEME.primaryDeep} strokeWidth="2" strokeLinecap="round" fill="none" />
              <circle cx="44" cy="37" r="0.6" fill="#fff" />
              <circle cx="52" cy="37" r="0.6" fill="#fff" />
            </svg>
          </div>

          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.16em', opacity: 0.75, fontWeight: 700 }}>Your Noor Points</div>

            {/* coin stack + big number */}
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14, marginTop: 10 }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <Coin size={56} />
                <Coin size={56} offset={-10} />
                <Coin size={56} offset={-10} />
                <Coin size={56} offset={-10} />
              </div>
              <div style={{ paddingBottom: 4 }}>
                <div style={{
                  fontSize: 52, fontWeight: 800, letterSpacing: '-0.04em',
                  lineHeight: 0.95, fontVariantNumeric: 'tabular-nums',
                }}>{useCountUp(points).toLocaleString()}</div>
                <div style={{ fontSize: 12, opacity: 0.8, marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{
                    padding: '2px 7px', borderRadius: 999,
                    background: V4_THEME.mint, color: '#0A3B2E',
                    fontWeight: 800, fontSize: 10,
                  }}>+127 today</span>
                  <span>pts</span>
                </div>
              </div>
            </div>

            {/* Validate CTA — big, tactile */}
            <button onClick={validate} disabled={validated} style={{
              marginTop: 18, width: '100%', padding: '15px 20px',
              border: 'none', borderRadius: 999,
              background: validated ? 'rgba(255,255,255,0.15)' : V4_THEME.coin,
              color: validated ? '#fff' : V4_THEME.primaryDeep,
              fontSize: 15, fontWeight: 800, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit', letterSpacing: '-0.01em',
              boxShadow: validated ? 'none' : '0 6px 0 0 rgba(0,0,0,0.12), 0 10px 20px rgba(255,194,51,0.4)',
              transition: 'all .15s',
              transform: validated ? 'translateY(2px)' : 'none',
            }}>
              {validated ? (
                <><Icon name="check" size={18} strokeWidth={3} />Validated · +85 locked</>
              ) : (
                <>VALIDATE TODAY<Icon name="arrow" size={16} strokeWidth={3} /></>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Streak strip — horizontal */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{
          background: V4_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V4_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: V4_THEME.inkSoft, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Login streak</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
                <span style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.03em' }}>12</span>
                <span style={{ fontSize: 12, color: V4_THEME.inkSoft }}>days · best 28</span>
              </div>
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6,
              padding: '6px 10px', borderRadius: 999,
              background: '#FFF1CC', color: '#8A6200',
              fontSize: 11, fontWeight: 700,
            }}>
              <Icon name="flame" size={13} strokeWidth={2.4} />
              Keep going
            </div>
          </div>
          <StreakDots days={4} today={4} accent={V4_THEME.primary} muted={V4_THEME.muted} />
        </div>
      </div>

      {/* Progress — bar chart style */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{
          background: V4_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V4_THEME.border}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ fontSize: 15, fontWeight: 800 }}>Progress</div>
            <TabPills tabs={['Today', 'Week', 'Month']} active={tab} onChange={setTab} theme={V4_THEME} />
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{ fontSize: 34, fontWeight: 800, letterSpacing: '-0.03em', color: V4_THEME.primary }}>
              {prog.toLocaleString()}
            </span>
            <span style={{ fontSize: 13, color: V4_THEME.inkSoft }}>/ {goal.toLocaleString()} pts</span>
          </div>
          {/* mini bar chart */}
          <div style={{ display: 'flex', gap: 6, alignItems: 'flex-end', marginTop: 12, height: 48 }}>
            {[34, 48, 62, 41, 72, 88, 55].map((h, i) => {
              const isToday = i === 5;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                  <div style={{
                    width: '100%', height: `${h}%`, minHeight: 6,
                    borderRadius: 6,
                    background: isToday ? V4_THEME.primary : V4_THEME.sky,
                    opacity: isToday ? 1 : 0.65,
                  }} />
                  <span style={{ fontSize: 9, color: V4_THEME.muted, fontWeight: 600 }}>
                    {['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]}
                  </span>
                </div>
              );
            })}
          </div>
          <div style={{ fontSize: 11, color: V4_THEME.muted, marginTop: 8 }}>
            {Math.round(pct)}% toward {tab.toLowerCase()} goal
          </div>
        </div>
      </div>

      {/* Earn row */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 2px 10px' }}>
          <div style={{ fontSize: 15, fontWeight: 800 }}>Earn more</div>
          <div style={{ fontSize: 12, color: V4_THEME.primary, fontWeight: 700 }}>See all →</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <V4Tile icon="book" label="Read Quran" sub="+15 / page" bg={V4_THEME.primary} fg="#fff" />
          <V4Tile
            icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target}`}
            bg={V4_THEME.mint} fg="#0A3B2E" onClick={dhikr.inc} tappable pulseKey={dhikr.pulse}
          />
          <V4Tile icon="hands" label="Duas" sub="3 of 5 today" bg={V4_THEME.lilac} fg="#fff" />
          <V4Tile icon="users" label="Invite" sub="+100 / friend" bg={V4_THEME.coral} fg="#fff" />
        </div>
      </div>

      {/* Donation */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          background: V4_THEME.surface, borderRadius: 22, padding: 16,
          border: `1px solid ${V4_THEME.border}`,
        }}>
          <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <div style={{
              width: 56, height: 56, borderRadius: 16, flexShrink: 0,
              background: `linear-gradient(135deg, ${V4_THEME.sky}, ${V4_THEME.primary})`,
              color: '#fff', display: 'flex',
              alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="heart" size={26} strokeWidth={2} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.1em', color: V4_THEME.inkSoft, fontWeight: 700 }}>Featured Sadaqah</div>
              <div style={{ fontSize: 15, fontWeight: 700, marginTop: 2, lineHeight: 1.3 }}>
                Clean water · 120 families in Yemen
              </div>
              <div style={{ fontSize: 11, color: V4_THEME.inkSoft, marginTop: 2 }}>
                100 pts = 1 day of water
              </div>
            </div>
          </div>
          <div style={{ marginTop: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, fontWeight: 700 }}>
              <span style={{ color: V4_THEME.ink }}>7,420 / 10,000 pts</span>
              <span style={{ color: V4_THEME.primary }}>74%</span>
            </div>
            <div style={{ marginTop: 6, height: 8, borderRadius: 999, background: V4_THEME.track }}>
              <div style={{
                height: '100%', width: '74%', borderRadius: 999,
                background: `linear-gradient(90deg, ${V4_THEME.primary}, ${V4_THEME.mint})`,
              }} />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
            {[50, 100, 250].map((v) => (
              <button key={v} style={{
                flex: 1, padding: '9px 0', borderRadius: 999,
                background: V4_THEME.track, border: 'none', color: V4_THEME.ink,
                fontSize: 12, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
              }}>{v} pts</button>
            ))}
            <button style={{
              flex: 1.2, padding: '9px 0', borderRadius: 999,
              background: V4_THEME.primary, border: 'none', color: '#fff',
              fontSize: 12, fontWeight: 800, cursor: 'pointer', fontFamily: 'inherit',
            }}>Donate →</button>
          </div>
        </div>
      </div>

    </div>
  );
}

function v4IconBtn() {
  return {
    width: 38, height: 38, borderRadius: 12, border: `1px solid ${V4_THEME.border}`,
    background: V4_THEME.surface, color: V4_THEME.ink,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer',
  };
}

function V4Tile({ icon, label, sub, bg, fg, onClick, tappable, pulseKey }) {
  const [scale, setScale] = React.useState(1);
  React.useEffect(() => {
    if (pulseKey === undefined) return;
    setScale(1.08);
    const t = setTimeout(() => setScale(1), 150);
    return () => clearTimeout(t);
  }, [pulseKey]);
  return (
    <button onClick={onClick} style={{
      background: bg, color: fg, borderRadius: 20, padding: 14,
      border: 'none', textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', display: 'flex', flexDirection: 'column',
      gap: 12, minHeight: 110, position: 'relative', overflow: 'hidden',
      transition: 'transform .15s', transform: `scale(${scale})`,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Icon name={icon} size={22} strokeWidth={2} />
        {tappable && (
          <span style={{
            fontSize: 9, fontWeight: 800, padding: '3px 6px',
            borderRadius: 999, background: 'rgba(0,0,0,0.15)',
          }}>TAP</span>
        )}
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 800, letterSpacing: '-0.01em' }}>{label}</div>
        <div style={{ fontSize: 11, opacity: 0.8, marginTop: 1 }}>{sub}</div>
      </div>
    </button>
  );
}

Object.assign(window, { V4Dashboard });
