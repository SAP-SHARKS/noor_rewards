// V1 — Classic Gamified dashboard
// Bold green hero, chunky cards, confetti on validate.

const V1_THEME = {
  bg: '#F5F0E6', // warm cream
  surface: '#FFFFFF',
  ink: '#14342B',
  inkSoft: '#4F6B62',
  muted: '#8FA39C',
  primary: '#1F9171', // emerald
  primaryDeep: '#0E5A44',
  gold: '#F5B700',
  goldSoft: '#FFE89A',
  rose: '#E94F7A',
  roseSoft: '#FFD9E4',
  cardBorder: 'rgba(20,52,43,0.06)',
  pillTrack: '#EBE3D3',
  pillOn: '#FFFFFF',
  pillOnText: '#14342B',
  pillText: '#8FA39C'
};

function V1Dashboard() {
  const [tab, setTab] = React.useState('This Week');
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

  const progress = {
    'Today': { value: 85, goal: 150, change: '+12 vs yesterday' },
    'This Week': { value: 612, goal: 1000, change: '+18%' },
    'This Month': { value: 2480, goal: 4000, change: '+7%' }
  }[tab];

  const pct = Math.min(100, progress.value / progress.goal * 100);

  return (
    <div style={{
      background: V1_THEME.bg, minHeight: '100%', position: 'relative',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
      color: V1_THEME.ink, paddingBottom: 24
    }}>
      <ConfettiBurst show={confetti} color={V1_THEME.gold} accent={V1_THEME.primary} />

      {/* Header row */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '18px 20px 12px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 44, height: 44, borderRadius: '50%',
            background: 'linear-gradient(135deg, #F5B700, #E94F7A)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontWeight: 700, fontSize: 18,
            boxShadow: '0 4px 12px rgba(233,79,122,0.3)'
          }}>AR</div>
          <div>
            <div style={{ fontSize: 12, color: V1_THEME.inkSoft, fontWeight: 500 }}>Assalamu Alaikum</div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>Ayesha R.</div>
          </div>
        </div>
        <button style={{
          width: 40, height: 40, borderRadius: '50%', border: 'none',
          background: V1_THEME.surface, color: V1_THEME.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', cursor: 'pointer',
          boxShadow: '0 1px 3px rgba(0,0,0,0.06)'
        }}>
          <Icon name="bell" size={20} />
          <span style={{
            position: 'absolute', top: 10, right: 11, width: 8, height: 8,
            borderRadius: '50%', background: V1_THEME.rose,
            border: `2px solid ${V1_THEME.surface}`
          }} />
        </button>
      </div>

      {/* Hero card — points */}
      <div style={{ padding: '4px 20px 0' }}>
        <div style={{
          background: `linear-gradient(155deg, ${V1_THEME.primary} 0%, ${V1_THEME.primaryDeep} 100%)`,
          borderRadius: 24, padding: '22px 22px 20px',
          position: 'relative', overflow: 'hidden',
          boxShadow: '0 8px 24px rgba(14,90,68,0.25)', color: "rgb(240, 229, 229)"
        }}>
          <div style={{ position: 'absolute', top: -20, right: -20, color: '#fff', opacity: 0.08 }}>
            <GeoStar size={160} color="#fff" />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 12, textTransform: 'uppercase', letterSpacing: '0.12em', opacity: 0.8, fontWeight: 600 }}>Total Noor Points</div>
            <div style={{ marginTop: 6 }}>
              <PointsNumber value={points} size={52} color="#fff" label="pts" labelColor="#fff" />
            </div>
            <div style={{ fontSize: 12, marginTop: 8, opacity: 0.85, display: 'flex', alignItems: 'center', gap: 6 }}>
              <Icon name="bolt" size={14} color={V1_THEME.gold} strokeWidth={2.4} />
              <span>+127 earned today · Rank 284</span>
            </div>

            {/* Validate CTA */}
            <button onClick={validate} disabled={validated} style={{
              marginTop: 16, width: '100%', padding: '14px 20px',
              border: 'none', borderRadius: 16,
              background: validated ? 'rgba(255,255,255,0.15)' : V1_THEME.gold,
              color: validated ? '#fff' : V1_THEME.primaryDeep,
              fontSize: 15, fontWeight: 700, cursor: validated ? 'default' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit',
              boxShadow: validated ? 'none' : '0 6px 16px rgba(245,183,0,0.4)',
              transition: 'all .2s'
            }}>
              {validated ?
              <>
                  <Icon name="check" size={18} strokeWidth={2.5} />
                  <span>Validated · +85 pts locked in</span>
                </> :

              <>
                  <Icon name="sparkle" size={18} />
                  <span>Validate today's points</span>
                </>
              }
            </button>
          </div>
        </div>
      </div>

      {/* Streak + Progress */}
      <div style={{ padding: '16px 20px 0', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* Streak card */}
        <div style={V1Card()}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: V1_THEME.inkSoft, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Daily streak</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
                <span style={{ fontSize: 28, fontWeight: 700, letterSpacing: '-0.02em' }}>12</span>
                <span style={{ fontSize: 13, color: V1_THEME.inkSoft }}>day streak</span>
              </div>
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6,
              padding: '6px 10px', borderRadius: 999,
              background: V1_THEME.goldSoft, color: '#8A6200',
              fontSize: 12, fontWeight: 600
            }}>
              <Icon name="flame" size={14} strokeWidth={2.2} />
              On fire
            </div>
          </div>
          <StreakDots days={4} today={4} accent={V1_THEME.primary} muted={V1_THEME.muted} />
        </div>

        {/* Progress card */}
        <div style={V1Card()}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Progress</div>
            <div style={{ fontSize: 12, color: V1_THEME.primary, fontWeight: 600 }}>{progress.change}</div>
          </div>
          <TabPills tabs={['Today', 'This Week', 'This Month']} active={tab} onChange={setTab} theme={V1_THEME} />
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 16 }}>
            <span style={{ fontSize: 36, fontWeight: 700, letterSpacing: '-0.02em' }}>
              {progress.value.toLocaleString()}
            </span>
            <span style={{ fontSize: 13, color: V1_THEME.inkSoft }}>
              of {progress.goal.toLocaleString()} pts
            </span>
          </div>
          <div style={{
            marginTop: 10, height: 10, borderRadius: 999,
            background: V1_THEME.pillTrack, overflow: 'hidden', position: 'relative'
          }}>
            <div style={{
              height: '100%', width: `${pct}%`,
              background: `linear-gradient(90deg, ${V1_THEME.primary}, ${V1_THEME.gold})`,
              borderRadius: 999, transition: 'width .6s cubic-bezier(.2,.7,.3,1)'
            }} />
          </div>
          <div style={{ fontSize: 11, color: V1_THEME.muted, marginTop: 8 }}>
            {Math.round(pct)}% toward {tab.toLowerCase()} goal
          </div>
        </div>

        {/* Quick actions */}
        <div>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            padding: '4px 2px 10px'
          }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Earn points</div>
            <div style={{ fontSize: 12, color: V1_THEME.inkSoft, fontWeight: 600 }}>See all</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <V1ActionCard icon="book" label="Read Quran" sub="+15 / page" points={15}
            bg="#E8F4EF" iconBg={V1_THEME.primary} iconColor="#fff" />
            <V1ActionCard
              icon="beads"
              label="Dhikr"
              sub={`${dhikr.count} / ${dhikr.target} today`}
              points={dhikr.count}
              onClick={dhikr.inc}
              bg="#FFF4D6"
              iconBg={V1_THEME.gold}
              iconColor="#fff"
              tappable
              pulseKey={dhikr.pulse} />
            
            <V1ActionCard icon="hands" label="Duas" sub="3 today" points={30}
            bg="#FFE4EC" iconBg={V1_THEME.rose} iconColor="#fff" />
            <V1ActionCard icon="users" label="Invite friends" sub="+100 per friend" points={100}
            bg="#E8EEF9" iconBg="#4C6EF5" iconColor="#fff" />
          </div>
        </div>

        {/* Donation */}
        <div style={{ ...V1Card(), padding: 0, overflow: 'hidden' }}>
          <div style={{
            background: `linear-gradient(135deg, ${V1_THEME.rose}, #C2185B)`,
            padding: 16, color: '#fff', position: 'relative', overflow: 'hidden'
          }}>
            <div style={{ position: 'absolute', right: -10, top: -10, opacity: 0.18 }}>
              <GeoStar size={110} color="#fff" />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.1em', opacity: 0.9, fontWeight: 600 }}>
              <Icon name="heart" size={14} strokeWidth={2.2} />
              Featured Sadaqah
            </div>
            <div style={{ fontSize: 18, fontWeight: 700, marginTop: 6, lineHeight: 1.25 }}>
              Clean water for 120 families in Yemen
            </div>
            <div style={{ fontSize: 12, opacity: 0.9, marginTop: 4 }}>
              Convert your points · every 100 pts = 1 day of water
            </div>
          </div>
          <div style={{ padding: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, fontWeight: 600 }}>
              <span style={{ color: V1_THEME.ink }}>7,420 / 10,000 pts raised</span>
              <span style={{ color: V1_THEME.rose }}>74%</span>
            </div>
            <div style={{
              marginTop: 8, height: 8, borderRadius: 999,
              background: V1_THEME.pillTrack, overflow: 'hidden'
            }}>
              <div style={{
                height: '100%', width: '74%',
                background: `linear-gradient(90deg, ${V1_THEME.rose}, ${V1_THEME.gold})`,
                borderRadius: 999
              }} />
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              {[50, 100, 250].map((v) =>
              <button key={v} style={V1ChipBtn()}>{v} pts</button>
              )}
              <button style={{ ...V1ChipBtn(), background: V1_THEME.ink, color: '#fff', borderColor: V1_THEME.ink, flex: 1.2 }}>
                Donate →
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>);

}

function V1Card() {
  return {
    background: V1_THEME.surface, borderRadius: 20, padding: 16,
    border: `1px solid ${V1_THEME.cardBorder}`,
    boxShadow: '0 1px 2px rgba(20,52,43,0.04)'
  };
}

function V1ChipBtn() {
  return {
    flex: 1, padding: '10px 0', borderRadius: 999,
    background: V1_THEME.surface, border: `1.5px solid ${V1_THEME.pillTrack}`,
    color: V1_THEME.ink, fontSize: 13, fontWeight: 600,
    fontFamily: 'inherit', cursor: 'pointer'
  };
}

function V1ActionCard({ icon, label, sub, points, bg, iconBg, iconColor, onClick, tappable, pulseKey }) {
  const [scale, setScale] = React.useState(1);
  React.useEffect(() => {
    if (pulseKey === undefined) return;
    setScale(1.1);
    const t = setTimeout(() => setScale(1), 150);
    return () => clearTimeout(t);
  }, [pulseKey]);

  return (
    <button onClick={onClick} style={{
      background: bg, borderRadius: 18, padding: 14,
      border: 'none', textAlign: 'left', cursor: 'pointer',
      fontFamily: 'inherit', display: 'flex', flexDirection: 'column',
      gap: 10, position: 'relative', overflow: 'hidden',
      transition: 'transform .15s',
      transform: `scale(${scale})`
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div style={{
          width: 36, height: 36, borderRadius: 12,
          background: iconBg, color: iconColor,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <Icon name={icon} size={18} strokeWidth={2} />
        </div>
        {tappable &&
        <span style={{
          fontSize: 10, fontWeight: 700, padding: '3px 7px',
          borderRadius: 999, background: 'rgba(255,255,255,0.7)',
          color: V1_THEME.ink
        }}>TAP</span>
        }
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: V1_THEME.ink }}>{label}</div>
        <div style={{ fontSize: 11, color: V1_THEME.inkSoft, marginTop: 2 }}>{sub}</div>
      </div>
    </button>);

}

Object.assign(window, { V1Dashboard });