// Shared utilities, icons, and hooks for Noor Rewards dashboards.
// All components exported to window at bottom.

// ─────────────────────────────────────────────────────────────
// Utility: line-icon set (stroke-based, consistent weight)
// ─────────────────────────────────────────────────────────────
const Icon = ({ name, size = 20, color = 'currentColor', strokeWidth = 1.8 }) => {
  const common = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  const paths = {
    crescent: <path d="M19 14.8A8 8 0 1 1 9.2 5a6.5 6.5 0 0 0 9.8 9.8z" />,
    sparkle: (
      <>
        <path d="M12 3v4M12 17v4M3 12h4M17 12h4" />
        <path d="M7 7l2 2M15 15l2 2M7 17l2-2M15 9l2-2" />
      </>
    ),
    flame: <path d="M12 3s4 4 4 8a4 4 0 1 1-8 0c0-2 1-3 1-5 2 2 3 2 3-3zM9.5 15a2.5 2.5 0 0 0 5 0" />,
    book: (
      <>
        <path d="M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z" />
        <path d="M4 5v16M19 3v16" />
      </>
    ),
    beads: (
      <>
        <circle cx="12" cy="5" r="2" />
        <circle cx="6" cy="9" r="1.6" />
        <circle cx="18" cy="9" r="1.6" />
        <circle cx="4" cy="15" r="1.4" />
        <circle cx="20" cy="15" r="1.4" />
        <circle cx="8" cy="19" r="1.4" />
        <circle cx="16" cy="19" r="1.4" />
      </>
    ),
    hands: (
      <>
        <path d="M8 12V5a1.5 1.5 0 0 1 3 0v5M11 10V4a1.5 1.5 0 0 1 3 0v6" />
        <path d="M14 10V6a1.5 1.5 0 0 1 3 0v7a7 7 0 0 1-14 0v-2a1.5 1.5 0 0 1 3 0" />
      </>
    ),
    heart: <path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z" />,
    users: (
      <>
        <circle cx="9" cy="8" r="3" />
        <circle cx="17" cy="10" r="2.5" />
        <path d="M3 20c0-3 3-5 6-5s6 2 6 5M14 20c0-2 2-4 4-4s3 1.5 3 4" />
      </>
    ),
    check: <path d="M4 12l5 5L20 6" />,
    chevron: <path d="M9 6l6 6-6 6" />,
    bolt: <path d="M13 3L4 14h7l-1 7 9-11h-7l1-7z" />,
    bell: <path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8zM10 21a2 2 0 0 0 4 0" />,
    star: <path d="M12 3l2.6 6 6.4.6-5 4.3 1.6 6.3L12 17l-5.6 3.2 1.6-6.3-5-4.3 6.4-.6z" />,
    plus: <path d="M12 5v14M5 12h14" />,
    arrow: <path d="M5 12h14M13 6l6 6-6 6" />,
    calendar: (
      <>
        <rect x="3" y="5" width="18" height="16" rx="2" />
        <path d="M3 10h18M8 3v4M16 3v4" />
      </>
    ),
    target: (
      <>
        <circle cx="12" cy="12" r="9" />
        <circle cx="12" cy="12" r="5" />
        <circle cx="12" cy="12" r="1.5" />
      </>
    ),
    mosque: (
      <>
        <path d="M12 3c0 2 2 2 2 4s-2 2-2 2-2 0-2-2 2-2 2-4z" />
        <path d="M4 21V11a4 4 0 0 1 4-4M20 21V11a4 4 0 0 0-4-4M4 21h16M9 21v-5a3 3 0 0 1 6 0v5" />
      </>
    ),
  };
  return <svg {...common}>{paths[name] || null}</svg>;
};

// ─────────────────────────────────────────────────────────────
// Decorative: 8-point Islamic star (geometric, clean)
// ─────────────────────────────────────────────────────────────
const GeoStar = ({ size = 40, color = 'currentColor', opacity = 1 }) => (
  <svg width={size} height={size} viewBox="0 0 40 40" style={{ opacity }}>
    <g fill="none" stroke={color} strokeWidth="1.2">
      <path d="M20 3 L25 10 L34 8 L32 17 L37 24 L29 28 L28 37 L20 33 L12 37 L11 28 L3 24 L8 17 L6 8 L15 10 Z" />
      <path d="M20 9 L23 14 L29 13 L27 19 L30 24 L25 26 L24 32 L20 30 L16 32 L15 26 L10 24 L13 19 L11 13 L17 14 Z" />
    </g>
  </svg>
);

// ─────────────────────────────────────────────────────────────
// Animated counter: tweens to target value on mount/change
// ─────────────────────────────────────────────────────────────
function useCountUp(target, duration = 900) {
  const [v, setV] = React.useState(target);
  const prev = React.useRef(target);
  React.useEffect(() => {
    const from = prev.current;
    const to = target;
    if (from === to) return;
    const start = performance.now();
    let raf;
    const tick = (t) => {
      const p = Math.min(1, (t - start) / duration);
      const e = 1 - Math.pow(1 - p, 3);
      setV(Math.round(from + (to - from) * e));
      if (p < 1) raf = requestAnimationFrame(tick);
      else prev.current = to;
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [target, duration]);
  return v;
}

// ─────────────────────────────────────────────────────────────
// Confetti burst (SVG, self-contained)
// ─────────────────────────────────────────────────────────────
function ConfettiBurst({ show, color = '#F5B700', accent = '#1f9171' }) {
  if (!show) return null;
  const pieces = Array.from({ length: 28 }, (_, i) => i);
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      overflow: 'hidden', zIndex: 50,
    }}>
      {pieces.map((i) => {
        const angle = (i / pieces.length) * Math.PI * 2;
        const dist = 120 + Math.random() * 80;
        const dx = Math.cos(angle) * dist;
        const dy = Math.sin(angle) * dist;
        const rot = Math.random() * 720 - 360;
        const col = [color, accent, '#ff7aa2', '#fff'][i % 4];
        const size = 6 + Math.random() * 6;
        return (
          <div key={i} style={{
            position: 'absolute', left: '50%', top: '45%',
            width: size, height: size * 0.45, background: col,
            borderRadius: 2,
            transform: `translate(-50%,-50%)`,
            animation: `noor-confetti-${i} 1.1s cubic-bezier(.2,.7,.3,1) forwards`,
          }} />
        );
      })}
      <style>{pieces.map((i) => {
        const angle = (i / pieces.length) * Math.PI * 2;
        const dist = 140 + (i % 5) * 20;
        const dx = Math.cos(angle) * dist;
        const dy = Math.sin(angle) * dist;
        const rot = (i * 47) % 720 - 360;
        return `@keyframes noor-confetti-${i}{
          0%{transform:translate(-50%,-50%) rotate(0) scale(.6);opacity:0}
          15%{opacity:1}
          100%{transform:translate(calc(-50% + ${dx}px),calc(-50% + ${dy}px)) rotate(${rot}deg) scale(1);opacity:0}
        }`;
      }).join('\n')}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Dhikr counter — increments on tap, haptic feel via scale
// ─────────────────────────────────────────────────────────────
function useDhikrCounter(initial = 14, target = 33) {
  const [count, setCount] = React.useState(initial);
  const [pulse, setPulse] = React.useState(0);
  const inc = () => {
    setCount((c) => (c >= target ? 0 : c + 1));
    setPulse((p) => p + 1);
  };
  return { count, target, inc, pulse };
}

// ─────────────────────────────────────────────────────────────
// Tab pill group
// ─────────────────────────────────────────────────────────────
function TabPills({ tabs, active, onChange, theme }) {
  return (
    <div style={{
      display: 'flex', gap: 4, padding: 4, borderRadius: 999,
      background: theme.pillTrack, width: '100%',
    }}>
      {tabs.map((t) => {
        const on = t === active;
        return (
          <button key={t} onClick={() => onChange(t)} style={{
            flex: 1, border: 'none', borderRadius: 999,
            padding: '8px 0', fontSize: 13, fontWeight: 600,
            background: on ? theme.pillOn : 'transparent',
            color: on ? theme.pillOnText : theme.pillText,
            cursor: 'pointer', fontFamily: 'inherit',
            transition: 'all .2s',
            boxShadow: on ? '0 1px 2px rgba(0,0,0,.08)' : 'none',
          }}>{t}</button>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Streak dots: 7-day row, filled / today / empty
// ─────────────────────────────────────────────────────────────
function StreakDots({ days, accent, muted, today = 4, onTap }) {
  // days: array of 7 booleans OR number of completed
  const completed = typeof days === 'number' ? days : days.filter(Boolean).length;
  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6 }}>
      {labels.map((l, i) => {
        const done = i < completed;
        const isToday = i === today;
        return (
          <button key={i} onClick={() => onTap && onTap(i)} style={{
            flex: 1, display: 'flex', flexDirection: 'column',
            alignItems: 'center', gap: 6, background: 'none',
            border: 'none', padding: 0, cursor: 'pointer',
            fontFamily: 'inherit',
          }}>
            <span style={{ fontSize: 10, color: muted, fontWeight: 600 }}>{l}</span>
            <span style={{
              width: 30, height: 30, borderRadius: '50%',
              background: done ? accent : 'transparent',
              border: isToday && !done ? `2px dashed ${accent}` : done ? 'none' : `1.5px solid ${muted}33`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: done ? '#fff' : muted,
              transition: 'transform .15s',
            }}>
              {done ? <Icon name="check" size={14} strokeWidth={2.5} /> : isToday ? '·' : ''}
            </span>
          </button>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Points hero — animated number with currency label
// ─────────────────────────────────────────────────────────────
function PointsNumber({ value, size = 56, color, label = 'points', labelColor }) {
  const v = useCountUp(value);
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
      <div style={{
        fontSize: size, fontWeight: 700, color,
        fontVariantNumeric: 'tabular-nums',
        letterSpacing: '-0.03em', lineHeight: 1,
        fontFamily: '"Plus Jakarta Sans", system-ui',
      }}>{v.toLocaleString()}</div>
      <div style={{ fontSize: 14, color: labelColor || color, opacity: 0.7, fontWeight: 500 }}>{label}</div>
    </div>
  );
}

Object.assign(window, {
  Icon, GeoStar, ConfettiBurst, useDhikrCounter, TabPills, StreakDots,
  PointsNumber, useCountUp,
});
