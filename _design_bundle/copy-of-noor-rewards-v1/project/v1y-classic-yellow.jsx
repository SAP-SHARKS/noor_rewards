// V1Y — Classic Gamified · YELLOW (bright marigold + canary)
// High-energy yellow: saturated, sunny, optimistic. Charcoal ink for contrast.

const V1Y_THEME = {
  bg: '#FFFBEB',                // warm cream
  surface: '#FFFFFF',
  ink: '#1F1A0E',               // near-black warm
  inkSoft: '#6B6452',
  muted: '#A89F87',
  primary: '#FFC83D',           // marigold (saturated)
  primaryDeep: '#9A6700',       // deep amber
  primarySoft: '#FFE89A',
  gold: '#F59E0B',
  rose: '#E94F7A',
  cardBorder: 'rgba(31,26,14,0.08)',
  pillTrack: '#F4ECD0',
  pillOn: '#FFFFFF',
  pillOnText: '#1F1A0E',
  pillText: '#A89F87',
};

function V1YDashboard() {
  const [tab, setTab] = React.useState('This Week');
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

  const progress = {
    'Today': { value: 85, goal: 150, change: '+12 vs yesterday' },
    'This Week': { value: 612, goal: 1000, change: '+18%' },
    'This Month': { value: 2480, goal: 4000, change: '+7%' },
  }[tab];
  const pct = Math.min(100, progress.value / progress.goal * 100);

  const card = {
    background: V1Y_THEME.surface, borderRadius: 20, padding: 16,
    border: `1px solid ${V1Y_THEME.cardBorder}`,
    boxShadow: '0 1px 2px rgba(31,26,14,0.04)',
  };

  return (
    <div style={{
      background: V1Y_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V1Y_THEME.ink, paddingBottom: 24,
    }}>
      <ConfettiBurst show={confetti} color={V1Y_THEME.primary} accent={V1Y_THEME.primaryDeep} />

      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '18px 20px 12px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 44, height: 44, borderRadius: '50%',
            background: `linear-gradient(135deg, ${V1Y_THEME.primary}, ${V1Y_THEME.gold})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: V1Y_THEME.ink, fontWeight: 700, fontSize: 18,
            boxShadow: `0 4px 12px ${V1Y_THEME.primary}66`,
          }}>AR</div>
          <div>
            <div style={{ fontSize: 12, color: V1Y_THEME.inkSoft, fontWeight: 500 }}>Assalamu Alaikum</div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>Ayesha R.</div>
          </div>
        </div>
        <button style={{
          width: 40, height: 40, borderRadius: '50%', border: 'none',
          background: V1Y_THEME.surface, color: V1Y_THEME.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', cursor: 'pointer',
          boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        }}>
          <Icon name="bell" size={20} />
          <span style={{
            position: 'absolute', top: 10, right: 11, width: 8, height: 8,
            borderRadius: '50%', background: V1Y_THEME.rose,
            border: `2px solid ${V1Y_THEME.surface}`,
          }} />
        </button>
      </div>

      {/* Hero — yellow gradient */}
      <div style={{ padding: '4px 20px 0' }}>
        <div style={{
          background: `linear-gradient(155deg, ${V1Y_THEME.primary} 0%, ${V1Y_THEME.gold} 100%)`,
          borderRadius: 24, padding: '22px 22px 20px',
          position: 'relative', overflow: 'hidden',
          boxShadow: `0 12px 28px ${V1Y_THEME.gold}44`,
          color: V1Y_THEME.ink,
        }}>
          <div style={{ position: 'absolute', top: -20, right: -20, opacity: 0.15 }}>
            <GeoStar size={160} color={V1Y_THEME.ink} />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 12, textTransform: 'uppercase', letterSpacing: '0.12em', opacity: 0.7, fontWeight: 700 }}>
              Total Noor Points
            </div>
            <div style={{ marginTop: 6 }}>
              <PointsNumber value={points} size={52} color={V1Y_THEME.ink} label="pts" labelColor={V1Y_THEME.ink} />
            </div>
            <div style={{ fontSize: 12, marginTop: 8, opacity: 0.8, display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
              <Icon name="bolt" size={14} strokeWidth={2.4} />
              <span>+127 earned today · Rank 284</span>
            </div>
            <button onClick={validate} disabled={validated} style={{
              marginTop: 16, width: '100%', padding: '14px 20px',
              border: 'none', borderRadius: 16,
              background: validated ? 'rgba(31,26,14,0.12)' : V1Y_THEME.ink,
              color: validated ? V1Y_THEME.ink : V1Y_THEME.primary,
              fontSize: 15, fontWeight: 700, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit',
              boxShadow: validated ? 'none' : '0 6px 16px rgba(31,26,14,0.3)',
            }}>
              {validated ? (
                <><Icon name="check" size={18} strokeWidth={2.5} />Validated · +85 pts</>
              ) : (
                <><Icon name="sparkle" size={18} />Validate today's points</>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Streak */}
      <div style={{ padding: '16px 20px 0', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={card}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: V1Y_THEME.inkSoft, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Daily streak</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
                <span style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em' }}>12</span>
                <span style={{ fontSize: 13, color: V1Y_THEME.inkSoft }}>day streak</span>
              </div>
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6,
              padding: '6px 10px', borderRadius: 999,
              background: V1Y_THEME.primarySoft, color: V1Y_THEME.primaryDeep,
              fontSize: 12, fontWeight: 700,
            }}>
              <Icon name="flame" size={14} strokeWidth={2.2} />
              On fire
            </div>
          </div>
          <StreakDots days={4} today={4} accent={V1Y_THEME.gold} muted={V1Y_THEME.muted} />
        </div>

        {/* Progress */}
        <div style={card}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Progress</div>
            <div style={{ fontSize: 12, color: V1Y_THEME.primaryDeep, fontWeight: 700 }}>{progress.change}</div>
          </div>
          <TabPills tabs={['Today', 'This Week', 'This Month']} active={tab} onChange={setTab} theme={V1Y_THEME} />
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 16 }}>
            <span style={{ fontSize: 36, fontWeight: 700, letterSpacing: '-0.02em' }}>
              {progress.value.toLocaleString()}
            </span>
            <span style={{ fontSize: 13, color: V1Y_THEME.inkSoft }}>
              of {progress.goal.toLocaleString()} pts
            </span>
          </div>
          <div style={{
            marginTop: 10, height: 10, borderRadius: 999,
            background: V1Y_THEME.pillTrack, overflow: 'hidden',
          }}>
            <div style={{
              height: '100%', width: `${pct}%`,
              background: `linear-gradient(90deg, ${V1Y_THEME.primary}, ${V1Y_THEME.gold})`,
              borderRadius: 999, transition: 'width .6s',
            }} />
          </div>
          <div style={{ fontSize: 11, color: V1Y_THEME.muted, marginTop: 8 }}>
            {Math.round(pct)}% toward {tab.toLowerCase()} goal
          </div>
        </div>

        {/* Quick actions */}
        <div>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            padding: '4px 2px 10px',
          }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Earn points</div>
            <div style={{ fontSize: 12, color: V1Y_THEME.inkSoft, fontWeight: 600 }}>See all</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <V1YAction icon="book" label="Read Quran" sub="+15 / page"
              bg="#FFF6D6" iconBg={V1Y_THEME.gold} iconColor={V1Y_THEME.ink} />
            <V1YAction icon="beads" label="Dhikr" sub={`${dhikr.count} / ${dhikr.target} today`}
              onClick={dhikr.inc}
              bg={V1Y_THEME.primary} iconBg={V1Y_THEME.ink} iconColor={V1Y_THEME.primary}
              tappable />
            <V1YAction icon="hands" label="Duas" sub="3 today"
              bg="#FFE9DA" iconBg="#E8825A" iconColor="#fff" />
            <V1YAction icon="users" label="Invite" sub="+100 per friend"
              bg="#F4ECD0" iconBg={V1Y_THEME.primaryDeep} iconColor="#FFE89A" />
          </div>
        </div>

        {/* Donation */}
        <div style={{ ...card, padding: 0, overflow: 'hidden' }}>
          <div style={{
            background: V1Y_THEME.ink,
            padding: 16, color: V1Y_THEME.primary, position: 'relative', overflow: 'hidden',
          }}>
            <div style={{ position: 'absolute', right: -10, top: -10, opacity: 0.15 }}>
              <GeoStar size={110} color={V1Y_THEME.primary} />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: 700 }}>
              <Icon name="heart" size={14} strokeWidth={2.2} />
              Featured Sadaqah
            </div>
            <div style={{ fontSize: 18, fontWeight: 800, marginTop: 6, lineHeight: 1.25, color: '#fff' }}>
              Clean water for 120 families in Yemen
            </div>
            <div style={{ fontSize: 12, opacity: 0.7, marginTop: 4, color: '#fff' }}>
              Convert your points · every 100 pts = 1 day of water
            </div>
          </div>
          <div style={{ padding: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, fontWeight: 700 }}>
              <span style={{ color: V1Y_THEME.ink }}>7,420 / 10,000 pts raised</span>
              <span style={{ color: V1Y_THEME.primaryDeep }}>74%</span>
            </div>
            <div style={{
              marginTop: 8, height: 8, borderRadius: 999,
              background: V1Y_THEME.pillTrack, overflow: 'hidden',
            }}>
              <div style={{
                height: '100%', width: '74%',
                background: `linear-gradient(90deg, ${V1Y_THEME.primary}, ${V1Y_THEME.gold})`,
                borderRadius: 999,
              }} />
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              {[50, 100, 250].map((v) => (
                <button key={v} style={{
                  flex: 1, padding: '10px 0', borderRadius: 999,
                  background: V1Y_THEME.surface, border: `1.5px solid ${V1Y_THEME.pillTrack}`,
                  color: V1Y_THEME.ink, fontSize: 13, fontWeight: 600,
                  fontFamily: 'inherit', cursor: 'pointer',
                }}>{v} pts</button>
              ))}
              <button style={{
                flex: 1.2, padding: '10px 0', borderRadius: 999,
                background: V1Y_THEME.primary, border: 'none',
                color: V1Y_THEME.ink, fontSize: 13, fontWeight: 800,
                cursor: 'pointer', fontFamily: 'inherit',
              }}>Donate →</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function V1YAction({ icon, label, sub, bg, iconBg, iconColor, onClick, tappable }) {
  return (
    <button onClick={onClick} style={{
      background: bg, borderRadius: 18, padding: 14,
      border: 'none', textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', display: 'flex', flexDirection: 'column',
      gap: 10, position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div style={{
          width: 36, height: 36, borderRadius: 12,
          background: iconBg, color: iconColor,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name={icon} size={18} strokeWidth={2} />
        </div>
        {tappable && (
          <span style={{
            fontSize: 10, fontWeight: 800, padding: '3px 7px',
            borderRadius: 999, background: 'rgba(31,26,14,0.85)',
            color: V1Y_THEME.primary,
          }}>TAP</span>
        )}
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 800, color: V1Y_THEME.ink }}>{label}</div>
        <div style={{ fontSize: 11, color: V1Y_THEME.inkSoft, marginTop: 2 }}>{sub}</div>
      </div>
    </button>
  );
}

Object.assign(window, { V1YDashboard });
