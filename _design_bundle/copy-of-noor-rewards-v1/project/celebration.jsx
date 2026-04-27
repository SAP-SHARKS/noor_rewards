// Dhikr/Dua celebration popup — dopamine-hit moment on exit.
// Shows: what you just completed + spiritual equivalents (MashaAllah framings)
// + points earned, streak, next challenge. Multiple aesthetic variants.

// ─────────────────────────────────────────────────────────────
// Shared: computes human-readable "blessings" for an azkar count
// ─────────────────────────────────────────────────────────────
function computeBlessings(count) {
  // Authentic-style hadith framings — playful but accurate in spirit
  return [
    { icon: '🌳', label: 'trees planted in Jannah', value: count },        // "Whoever says SubhanAllah…"
    { icon: '🕊️', label: 'sins forgiven, inshaAllah', value: count * 10 },
    { icon: '🤲', label: 'supplications ascending', value: Math.ceil(count / 3) },
  ];
}

const DHIKR_COUNT = 33;
const POINTS_EARNED = 66;
const DUAS = 3;

// ═════════════════════════════════════════════════════════════
// Variant A — "Stardust Ceremony" (dark, dramatic, full-screen)
// ═════════════════════════════════════════════════════════════

function CelebA({ onClose }) {
  const [showStats, setShowStats] = React.useState(false);
  React.useEffect(() => {
    const t = setTimeout(() => setShowStats(true), 800);
    return () => clearTimeout(t);
  }, []);
  const blessings = computeBlessings(DHIKR_COUNT);

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'radial-gradient(ellipse at 50% 30%, #3B2A8A 0%, #0F0B2E 65%)',
      color: '#F5F1FF', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
    }}>
      {/* starfield */}
      <V8StarField count={60} />
      <ConfettiBurst show={true} color="#F4C65A" accent="#7C5CFF" />

      {/* rays */}
      <svg style={{ position: 'absolute', top: '15%', left: '50%', transform: 'translateX(-50%)', opacity: 0.35 }} width="300" height="300" viewBox="0 0 300 300">
        <defs>
          <radialGradient id="rayGrad"><stop offset="0%" stopColor="#F4C65A" stopOpacity="0.8" /><stop offset="100%" stopColor="#F4C65A" stopOpacity="0" /></radialGradient>
        </defs>
        {Array.from({ length: 12 }).map((_, i) => (
          <rect key={i} x="148" y="0" width="4" height="150" fill="url(#rayGrad)"
            transform={`rotate(${i * 30} 150 150)`}>
            <animate attributeName="opacity" values="0.4;0.9;0.4" dur={`${3 + i * 0.2}s`} repeatCount="indefinite" />
          </rect>
        ))}
      </svg>

      {/* close */}
      <button onClick={onClose} style={{
        position: 'absolute', top: 16, right: 16, zIndex: 2,
        width: 34, height: 34, borderRadius: '50%',
        background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.15)',
        color: '#F5F1FF', fontSize: 16, cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>✕</button>

      <div style={{ padding: '50px 24px 20px', textAlign: 'center', position: 'relative', zIndex: 2 }}>
        {/* badge */}
        <div style={{
          width: 100, height: 100, margin: '0 auto',
          position: 'relative', animation: 'spinSlow 20s linear infinite',
        }}>
          <GeoStar size={100} color="#F4C65A" opacity={0.9} />
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: '"Instrument Serif", serif',
            fontSize: 32, color: '#F4C65A',
            animation: 'spinSlow 20s linear infinite reverse',
          }}>ﷲ</div>
        </div>

        <div style={{
          marginTop: 20, fontSize: 11, letterSpacing: '0.3em',
          color: '#F4C65A', fontWeight: 700, textTransform: 'uppercase',
        }}>· Barakallahu feek ·</div>

        <div style={{
          fontFamily: '"Instrument Serif", serif', fontSize: 40,
          fontWeight: 400, marginTop: 10, lineHeight: 1.05,
          letterSpacing: '-0.02em',
        }}>
          MashaAllah,<br />
          <em style={{ fontStyle: 'italic', color: '#F4C65A' }}>beautiful work</em>
        </div>

        <div style={{ fontSize: 14, color: 'rgba(245,241,255,0.75)', marginTop: 10, lineHeight: 1.4 }}>
          You just completed <strong style={{ color: '#fff' }}>{DHIKR_COUNT} azkaar</strong>
          {DUAS > 0 && <> &amp; <strong style={{ color: '#fff' }}>{DUAS} duas</strong></>}
        </div>
      </div>

      {/* Stats reveal */}
      <div style={{
        flex: 1, padding: '10px 24px 0',
        opacity: showStats ? 1 : 0, transform: showStats ? 'translateY(0)' : 'translateY(20px)',
        transition: 'all .6s ease-out',
      }}>
        <div style={{
          background: 'rgba(255,255,255,0.06)', borderRadius: 22,
          border: '1px solid rgba(244,198,90,0.25)',
          padding: '18px 16px', backdropFilter: 'blur(12px)',
        }}>
          <div style={{
            fontSize: 10, letterSpacing: '0.18em', textAlign: 'center',
            color: '#F4C65A', fontWeight: 700, textTransform: 'uppercase',
          }}>· What you earned ·</div>

          {blessings.map((b, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '12px 4px',
              borderBottom: i < blessings.length - 1 ? '1px solid rgba(255,255,255,0.07)' : 'none',
            }}>
              <div style={{ fontSize: 24, width: 32, textAlign: 'center' }}>{b.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{
                  fontFamily: '"Instrument Serif", serif', fontSize: 26,
                  color: '#F4C65A', lineHeight: 1, letterSpacing: '-0.02em',
                }}>{b.value.toLocaleString()}</div>
                <div style={{ fontSize: 11, color: 'rgba(245,241,255,0.7)', marginTop: 2 }}>
                  {b.label}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Points ticker */}
        <div style={{
          marginTop: 14, padding: '14px 16px',
          borderRadius: 18,
          background: 'linear-gradient(135deg, #F4C65A 0%, #DFA032 100%)',
          color: '#0F0B2E', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.14em', textTransform: 'uppercase', opacity: 0.7 }}>
              Noor added
            </div>
            <div style={{
              fontFamily: '"Instrument Serif", serif', fontSize: 32,
              lineHeight: 1, marginTop: 2, fontVariantNumeric: 'tabular-nums',
            }}>
              +{POINTS_EARNED}
            </div>
          </div>
          <Icon name="sparkle" size={28} strokeWidth={1.8} />
        </div>
      </div>

      {/* CTAs */}
      <div style={{ padding: '16px 24px 24px', display: 'flex', gap: 10, position: 'relative', zIndex: 2 }}>
        <button onClick={onClose} style={{
          flex: 1, padding: '13px', borderRadius: 999,
          background: 'transparent', border: '1px solid rgba(255,255,255,0.2)',
          color: '#F5F1FF', fontSize: 13, fontWeight: 600, cursor: 'pointer',
          fontFamily: 'inherit',
        }}>Done</button>
        <button style={{
          flex: 1.6, padding: '13px', borderRadius: 999,
          background: '#F4C65A', border: 'none',
          color: '#0F0B2E', fontSize: 13, fontWeight: 700, cursor: 'pointer',
          fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>
          <Icon name="heart" size={15} strokeWidth={2.2} />
          Donate to save a family
        </button>
      </div>

      <style>{`
        @keyframes spinSlow { to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// Variant B — "Garden Bloom" (warm, playful, half-screen sheet)
// ═════════════════════════════════════════════════════════════

function CelebB({ onClose }) {
  const blessings = computeBlessings(DHIKR_COUNT);

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(46,59,42,0.55)', backdropFilter: 'blur(4px)',
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
      fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
    }}>
      <ConfettiBurst show={true} color="#FFD66E" accent="#FFB088" />

      <div style={{
        background: '#FFF9EE', borderRadius: '32px 32px 0 0',
        padding: '12px 0 0', position: 'relative',
        boxShadow: '0 -20px 60px rgba(0,0,0,0.2)',
        animation: 'slideUp .5s cubic-bezier(.2,.9,.3,1.2)',
      }}>
        <div style={{
          width: 40, height: 4, borderRadius: 999,
          background: '#EFE6D6', margin: '0 auto',
        }} />

        {/* Hero illustration */}
        <div style={{ padding: '18px 24px 0', textAlign: 'center', position: 'relative' }}>
          <div style={{
            display: 'inline-flex', alignItems: 'flex-end', gap: 6,
            padding: '0 0 4px',
          }}>
            {/* dates + plants */}
            <svg width="40" height="60" viewBox="0 0 40 60">
              <rect x="17" y="28" width="4" height="32" fill="#8A5A3B" />
              <path d="M19 28 Q5 18 2 10 Q12 12 19 24 Z" fill="#6B9E6F" />
              <path d="M19 28 Q33 18 36 10 Q26 12 19 24 Z" fill="#6B9E6F" />
              <circle cx="16" cy="28" r="2" fill="#E8825A" />
              <circle cx="22" cy="30" r="2" fill="#E8825A" />
            </svg>
            <div style={{ fontSize: 54, lineHeight: 1 }}>🌸</div>
            <svg width="40" height="70" viewBox="0 0 40 70">
              <rect x="16" y="22" width="8" height="4" fill="#8A5A3B" />
              <rect x="14" y="26" width="12" height="34" rx="1" fill="#8A5A3B" />
              <path d="M20 22 Q8 10 4 2 Q16 4 20 18 Z" fill="#6B9E6F" />
              <path d="M20 22 Q32 10 36 2 Q24 4 20 18 Z" fill="#3F6A48" />
              <circle cx="20" cy="14" r="4" fill="#FFD66E" />
            </svg>
          </div>

          <div style={{
            fontSize: 10, letterSpacing: '0.22em',
            color: '#3F6A48', fontWeight: 700, textTransform: 'uppercase', marginTop: 4,
          }}>Your garden grew</div>

          <div style={{
            fontFamily: '"Fraunces", "Instrument Serif", serif',
            fontSize: 32, fontWeight: 400, color: '#2E3B2A',
            marginTop: 6, lineHeight: 1.1, letterSpacing: '-0.02em',
          }}>
            MashaAllah! <em style={{ fontStyle: 'italic', color: '#E8825A' }}>Beautiful.</em>
          </div>
          <div style={{ fontSize: 13, color: '#6B7863', marginTop: 6, lineHeight: 1.4 }}>
            {DHIKR_COUNT} azkaar · {DUAS} duas · 6 minutes of noor
          </div>
        </div>

        {/* Stats strip */}
        <div style={{
          margin: '16px 18px 0', padding: '14px',
          background: '#FFF', borderRadius: 18,
          border: '1px solid rgba(46,59,42,0.08)',
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6,
        }}>
          {blessings.map((b, i) => (
            <div key={i} style={{
              textAlign: 'center', padding: '6px 4px',
              borderRight: i < blessings.length - 1 ? '1px solid rgba(46,59,42,0.08)' : 'none',
            }}>
              <div style={{ fontSize: 22 }}>{b.icon}</div>
              <div style={{
                fontFamily: '"Fraunces", serif', fontSize: 22,
                color: '#3F6A48', lineHeight: 1, marginTop: 3,
              }}>{b.value.toLocaleString()}</div>
              <div style={{ fontSize: 9, color: '#6B7863', marginTop: 3, lineHeight: 1.2, fontWeight: 600 }}>
                {b.label}
              </div>
            </div>
          ))}
        </div>

        {/* Points bar */}
        <div style={{
          margin: '12px 18px 0', padding: '14px 16px',
          background: '#3F6A48', color: '#FFF9EE', borderRadius: 16,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{ fontSize: 11, color: '#FFD66E', fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
              Noor earned
            </div>
            <div style={{
              fontFamily: '"Fraunces", serif', fontSize: 30, lineHeight: 1, marginTop: 2,
              fontVariantNumeric: 'tabular-nums',
            }}>+{POINTS_EARNED} pts</div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 11, opacity: 0.7 }}>🔥 Streak</div>
            <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>13 days</div>
          </div>
        </div>

        {/* hadith-inspired quote */}
        <div style={{
          margin: '14px 24px 0',
          fontFamily: '"Fraunces", serif', fontStyle: 'italic',
          fontSize: 13, lineHeight: 1.45, color: '#6B7863', textAlign: 'center',
        }}>
          "Whoever says SubhanAllah 100 times, a thousand good deeds
          are recorded for him."
          <div style={{ fontSize: 10, fontStyle: 'normal', marginTop: 4, color: '#AEB8A8', letterSpacing: '0.08em', fontWeight: 700 }}>
            — SAHIH MUSLIM
          </div>
        </div>

        {/* CTA */}
        <div style={{ padding: '16px 18px 22px', display: 'flex', gap: 8 }}>
          <button onClick={onClose} style={{
            flex: 1, padding: '13px', borderRadius: 14,
            background: '#EFE6D6', border: 'none',
            color: '#2E3B2A', fontSize: 13, fontWeight: 700, cursor: 'pointer',
            fontFamily: 'inherit',
          }}>Alhamdulillah</button>
          <button style={{
            flex: 1.5, padding: '13px', borderRadius: 14,
            background: '#E8825A', border: 'none',
            color: '#fff', fontSize: 13, fontWeight: 700, cursor: 'pointer',
            fontFamily: 'inherit', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
            🌳 Plant a tree →
          </button>
        </div>
      </div>

      <style>{`
        @keyframes slideUp { from { transform: translateY(100%); } to { transform: translateY(0); } }
      `}</style>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// Variant C — "Manuscript Seal" (parchment, ceremonial, centered card)
// ═════════════════════════════════════════════════════════════

function CelebC({ onClose }) {
  const blessings = computeBlessings(DHIKR_COUNT);

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(43,31,26,0.5)', backdropFilter: 'blur(4px)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 20, fontFamily: '"Plus Jakarta Sans", system-ui, sans-serif',
    }}>
      <ConfettiBurst show={true} color="#B04A2C" accent="#E8A84A" />

      <div style={{
        background: '#FBF3E2', borderRadius: 6,
        border: '2px solid #B04A2C', padding: 5,
        width: '100%', maxWidth: 360, position: 'relative',
        boxShadow: '0 30px 80px rgba(43,31,26,0.4)',
        animation: 'popIn .45s cubic-bezier(.2,.9,.3,1.3)',
      }}>
        <div style={{
          border: '1px solid #B04A2C', padding: '22px 20px 18px',
          position: 'relative',
        }}>
          <button onClick={onClose} style={{
            position: 'absolute', top: 10, right: 10,
            width: 26, height: 26, borderRadius: '50%',
            background: 'transparent', border: '1px solid rgba(43,31,26,0.15)',
            color: '#6B5A4E', fontSize: 12, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>✕</button>

          {/* Arabesque corners */}
          {[0, 90, 180, 270].map((r, i) => (
            <div key={i} style={{
              position: 'absolute',
              top: r === 0 || r === 90 ? 10 : 'auto',
              bottom: r === 180 || r === 270 ? 10 : 'auto',
              left: r === 0 || r === 270 ? 10 : 'auto',
              right: r === 90 || r === 180 ? 10 : 'auto',
            }}>
              <V7Flourish size={16} color="#B04A2C" rotate={r} />
            </div>
          ))}

          {/* Seal */}
          <div style={{ textAlign: 'center', paddingTop: 8 }}>
            <div style={{
              width: 76, height: 76, borderRadius: '50%',
              border: '2px solid #B04A2C', margin: '0 auto',
              background: 'radial-gradient(circle, #E8A84A 0%, #B04A2C 80%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative',
              boxShadow: 'inset 0 0 10px rgba(122,46,22,0.5)',
            }}>
              <div style={{
                fontFamily: '"Instrument Serif", serif', fontSize: 36, color: '#FBF3E2',
              }}>ﷺ</div>
              <div style={{
                position: 'absolute', inset: -4, borderRadius: '50%',
                border: '1px dashed #B04A2C', opacity: 0.4,
              }} />
            </div>

            <div style={{
              fontSize: 10, letterSpacing: '0.26em', color: '#B04A2C',
              fontWeight: 700, textTransform: 'uppercase', marginTop: 14,
            }}>· Today's ledger is sealed ·</div>

            <div style={{
              fontFamily: '"Instrument Serif", serif', fontSize: 30,
              color: '#7A2E16', marginTop: 8, lineHeight: 1.1,
              letterSpacing: '-0.02em',
            }}>
              <em style={{ fontStyle: 'italic' }}>MashaAllah</em>, Ayesha
            </div>
            <div style={{
              fontSize: 12, color: '#6B5A4E', marginTop: 6,
              fontFamily: '"Instrument Serif", serif', fontStyle: 'italic',
            }}>
              — {DHIKR_COUNT} azkaar &amp; {DUAS} duas inscribed today —
            </div>
          </div>

          {/* Rule */}
          <div style={{
            height: 1, background: 'rgba(43,31,26,0.2)',
            margin: '18px -20px',
          }} />

          {/* Ledger rows */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {blessings.map((b, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                fontFamily: '"Instrument Serif", serif',
              }}>
                <span style={{
                  fontSize: 11, color: '#A89681', fontStyle: 'italic',
                  width: 18, textAlign: 'right',
                }}>{['ⅰ', 'ⅱ', 'ⅲ'][i]}</span>
                <span style={{ fontSize: 18 }}>{b.icon}</span>
                <span style={{
                  fontFamily: '"Instrument Serif", serif', fontSize: 22,
                  color: '#7A2E16', fontVariantNumeric: 'tabular-nums',
                  minWidth: 60,
                }}>{b.value.toLocaleString()}</span>
                <span style={{
                  fontSize: 12, color: '#6B5A4E', fontStyle: 'italic', flex: 1,
                }}>{b.label}</span>
              </div>
            ))}
          </div>

          {/* Points */}
          <div style={{
            marginTop: 18,
            background: '#3A3A8B', color: '#FBF3E2',
            padding: '10px 14px', borderRadius: 2,
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            border: '1px solid #E8A84A',
          }}>
            <span style={{ fontSize: 11, letterSpacing: '0.15em', textTransform: 'uppercase', color: '#E8A84A', fontWeight: 700 }}>
              Noor inscribed
            </span>
            <span style={{
              fontFamily: '"Instrument Serif", serif', fontSize: 24,
              color: '#E8A84A', fontVariantNumeric: 'tabular-nums',
            }}>+{POINTS_EARNED}</span>
          </div>

          {/* CTAs */}
          <div style={{ marginTop: 14, display: 'flex', gap: 8 }}>
            <button onClick={onClose} style={{
              flex: 1, padding: '11px 12px',
              background: 'transparent', border: '1px solid rgba(43,31,26,0.2)',
              color: '#6B5A4E', fontSize: 11, fontWeight: 700, cursor: 'pointer',
              letterSpacing: '0.12em', textTransform: 'uppercase', fontFamily: 'inherit',
            }}>Close</button>
            <button style={{
              flex: 1.5, padding: '11px 12px',
              background: '#B04A2C', border: '1px solid #7A2E16',
              color: '#FBF3E2', fontSize: 11, fontWeight: 700, cursor: 'pointer',
              letterSpacing: '0.12em', textTransform: 'uppercase', fontFamily: 'inherit',
            }}>Share a Sadaqah →</button>
          </div>
        </div>
      </div>

      <style>{`
        @keyframes popIn { from { transform: scale(.9); opacity: 0; } to { transform: scale(1); opacity: 1; } }
      `}</style>
    </div>
  );
}

Object.assign(window, { CelebA, CelebB, CelebC });
