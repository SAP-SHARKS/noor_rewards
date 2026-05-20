"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";

// Pixel-perfect SVG component representing Sabiq Coin (Noor S Coin) from Flutter painter.
// Scaled mathematically relative to a 180-unit reference grid.
function SabiqCoin({ size = 40, sprouting = false, className = "" }: { size?: number; sprouting?: boolean; className?: string }) {
  const dots = [];
  // 12 dots evenly spaced at gold orbit radius = 76 (86 - 10)
  for (let i = 0; i < 12; i++) {
    const angle = -Math.PI / 2 + i * (Math.PI * 2 / 12);
    const x = 90 + 76 * Math.cos(angle);
    const y = 90 + 76 * Math.sin(angle);
    dots.push(
      <circle key={i} cx={x} cy={y} r={1.8} fill="#5C3A0A" opacity={0.5} />
    );
  }

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 180 180"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        {/* Outer Ring Gold Radial Gradient */}
        <radialGradient
          id="goldRadial"
          cx="35%"
          cy="30%"
          r="90%"
          fx="35%"
          fy="30%"
        >
          <stop offset="0%" stopColor="#FFE89A" />
          <stop offset="55%" stopColor="#E8B84A" />
          <stop offset="100%" stopColor="#8B6420" />
        </radialGradient>

        {/* Inner Emerald Disc Radial Gradient */}
        <radialGradient
          id="emeraldRadial"
          cx="35%"
          cy="30%"
          r="90%"
          fx="35%"
          fy="30%"
        >
          <stop offset="0%" stopColor="#7FCFA8" />
          <stop offset="50%" stopColor="#4A9B8E" />
          <stop offset="100%" stopColor="#1F4F3D" />
        </radialGradient>

        {/* Bold Italic S Gold Linear Gradient */}
        <linearGradient id="sGoldGrad" x1="20%" y1="0%" x2="80%" y2="100%">
          <stop offset="0%" stopColor="#FFFAEC" />
          <stop offset="50%" stopColor="#FFD662" />
          <stop offset="100%" stopColor="#A37520" />
        </linearGradient>

        {/* Cream Highlight for S */}
        <linearGradient id="sCreamGrad" x1="20%" y1="0%" x2="80%" y2="100%">
          <stop offset="0%" stopColor="#FFFAEC" stopOpacity="0.6" />
          <stop offset="100%" stopColor="#FFFAEC" stopOpacity="0" />
        </linearGradient>
      </defs>

      {/* Sprouting Leaf (Sprouting S variant) */}
      {sprouting && (
        <g transform="translate(110, 42) rotate(25)">
          <path
            d="M 0 0 Q 12 -3 14 -10 Q 8 -8 0 0 Z"
            fill="#4A9B8E"
            stroke="#1F4F3D"
            strokeWidth="2.5"
            strokeLinejoin="round"
          />
        </g>
      )}

      {/* Outer Ring */}
      <circle
        cx="90"
        cy="90"
        r="86"
        fill="url(#goldRadial)"
        stroke="#5C3A0A"
        strokeWidth="2.5"
      />

      {/* 12 Decorative Dots */}
      {dots}

      {/* Gold ring top-left sheen */}
      <ellipse cx="60" cy="55" rx="22" ry="12" fill="#FFFAEC" opacity="0.45" />

      {/* Inner Emerald Disc */}
      <circle
        cx="90"
        cy="90"
        r="62"
        fill="url(#emeraldRadial)"
        stroke="#1F4F3D"
        strokeWidth="1.5"
      />

      {/* Emerald disc top-left sheen */}
      <ellipse cx="72" cy="72" rx="20" ry="11" fill="#A8E0C5" opacity="0.5" />

      {/* Bold Italic "S" body mark */}
      <text
        x="90"
        y="98"
        textAnchor="middle"
        dominantBaseline="central"
        fontFamily="Fraunces, Georgia, serif"
        fontSize="108"
        fontWeight="900"
        fontStyle="italic"
        fill="url(#sGoldGrad)"
        stroke="#5C3A0A"
        strokeWidth="1.2"
        style={{ userSelect: "none" }}
      >
        S
      </text>

      {/* Cream Highlight Overlay */}
      <text
        x="90"
        y="98"
        textAnchor="middle"
        dominantBaseline="central"
        fontFamily="Fraunces, Georgia, serif"
        fontSize="108"
        fontWeight="900"
        fontStyle="italic"
        fill="url(#sCreamGrad)"
        opacity="0.4"
        style={{ userSelect: "none", pointerEvents: "none" }}
      >
        S
      </text>
    </svg>
  );
}

function JoinPageContent() {
  const searchParams = useSearchParams();
  const referralCode = searchParams.get("ref") || "";

  const [copied, setCopied] = useState(false);
  const [os, setOs] = useState<"ios" | "android" | "other">("other");
  const [dhikrCount, setDhikrCount] = useState(12);
  const [seeds, setSeeds] = useState(1250);
  const [showSeedBonus, setShowSeedBonus] = useState(false);

  useEffect(() => {
    // Detect operating system
    const userAgent = navigator.userAgent || navigator.vendor || (window as any).opera;
    if (/iPad|iPhone|iPod/.test(userAgent) && !(window as any).MSStream) {
      setOs("ios");
    } else if (/android/i.test(userAgent)) {
      setOs("android");
    } else {
      setOs("other");
    }
  }, []);

  const handleCopy = () => {
    if (!referralCode) return;
    navigator.clipboard.writeText(referralCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDhikrTap = () => {
    if (dhikrCount < 33) {
      setDhikrCount((prev) => prev + 1);
      setSeeds((prev) => prev + 5);
      if (dhikrCount + 1 === 33) {
        setShowSeedBonus(true);
        setSeeds((prev) => prev + 50); // Tasbih completion bonus!
        setTimeout(() => setShowSeedBonus(false), 3000);
      }
    } else {
      // Reset count
      setDhikrCount(0);
    }
  };

  const getDownloadLink = () => {
    if (os === "ios") {
      return "https://apps.apple.com/app/sabiq-rewards"; // Live App Store URL
    }
    return "https://play.google.com/store/apps/details?id=com.example.noor_rewards"; // Live Play Store URL
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-[#FFFDF8] via-[#FFFBF0] to-[#FFF4D2] text-[#2A2410] px-4 py-12 relative overflow-hidden font-sans">
      {/* Import premium Sabiq Fonts (Fraunces for S Coin, Outfit for App Headlines, Rajdhani for level numbers) */}
      <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,100..900;1,9..144,100..900&family=Outfit:wght@100..900&family=Rajdhani:wght@300..700&display=swap" rel="stylesheet" />

      {/* Dynamic ambient backgrounds */}
      <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] rounded-full bg-[#7A8C3A]/6 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] rounded-full bg-[#FFC83D]/10 blur-[120px] pointer-events-none" />
      
      {/* Upper Header */}
      <div className="w-full max-w-5xl mb-8 flex items-center justify-between z-10 px-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 flex items-center justify-center filter drop-shadow-sm transition-transform duration-300 hover:scale-105">
            <SabiqCoin size={36} sprouting={true} />
          </div>
          <span className="font-extrabold tracking-widest text-xl text-[#2A2410]" style={{ fontFamily: "Outfit, sans-serif" }}>
            SABIQ
          </span>
        </div>
        {/* "Islamic Rewards App" tag successfully removed */}
      </div>

      {/* Main Grid Layout */}
      <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-12 gap-8 items-center z-10 px-2 lg:px-4">
        
        {/* Left Column: The Invitation Details */}
        <div className="lg:col-span-7 flex flex-col justify-center space-y-6">
          <div className="bg-white/70 backdrop-blur-xl border border-[#7A8C3A]/10 rounded-3xl p-8 lg:p-10 shadow-xl shadow-[#2A2410]/5 relative overflow-hidden">
            
            {/* Elegant Top Decorative Border */}
            <div className="absolute top-0 left-0 right-0 h-[4px] bg-gradient-to-r from-[#7A8C3A] via-[#FFC83D] to-[#D89A1E]" />

            <div className="flex items-center gap-3 text-[#7A8C3A] font-bold text-xs uppercase tracking-widest mb-4">
              <span className="flex h-2 w-2 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#7A8C3A] opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-[#7A8C3A]"></span>
              </span>
              Personal Invitation
            </div>

            <h1 className="text-4xl lg:text-5xl font-black tracking-tight leading-tight text-[#2A2410] font-sans" style={{ fontFamily: "Outfit, sans-serif" }}>
              You've Been Invited to <span className="bg-gradient-to-r from-[#7A8C3A] via-[#D89A1E] to-[#697931] bg-clip-text text-transparent">Sabiq</span>!
            </h1>
            
            <p className="text-[#5C543A] text-base lg:text-lg mt-4 leading-relaxed font-medium">
              Join Sabiq to walk the path of light, track your daily Quran & Dhikr, and earn rewarding Seeds.
            </p>

            {/* Premium Sabiq Redesigned Referral Invitation Card */}
            {referralCode && (
              <div className="mt-8 bg-gradient-to-br from-[#FFFDF2] to-[#FFF9E6] border-2 border-[#D89A1E]/25 rounded-3xl p-6 lg:p-8 relative overflow-hidden shadow-lg shadow-[#2A2410]/5 transition-all duration-300 hover:border-[#D89A1E]/40">
                {/* Decorative border accent */}
                <div className="absolute top-0 left-0 right-0 h-[4px] bg-gradient-to-r from-[#D89A1E] via-[#FFC83D] to-[#7A8C3A]" />
                
                {/* Micro dots pattern in background */}
                <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[radial-gradient(#5C3A0A_1px,transparent_1px)] [background-size:16px_16px]" />
                
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
                  {/* Left Column: Reward details */}
                  <div className="flex items-start gap-4">
                    <div className="w-14 h-14 rounded-2xl bg-white border border-[#D89A1E]/20 shadow-md p-1.5 flex items-center justify-center flex-shrink-0 animate-bounce">
                      <SabiqCoin size={42} sprouting={true} />
                    </div>
                    <div>
                      <span className="inline-block text-[10px] font-extrabold tracking-widest text-[#7A8C3A] uppercase bg-[#7A8C3A]/10 px-2.5 py-1 rounded-full border border-[#7A8C3A]/10">
                        Signup Reward
                      </span>
                      <h4 className="text-xl font-black text-[#2A2410] mt-1.5 leading-tight" style={{ fontFamily: "Outfit, sans-serif" }}>
                        Claim <span className="text-[#D89A1E] font-extrabold">500 Seeds</span>
                      </h4>
                      <p className="text-xs text-[#5C543A] mt-1 leading-normal font-medium max-w-[280px]">
                        Both you and the inviter receive a <span className="font-bold text-[#D89A1E]">500 Seeds bonus</span> the instant you join!
                      </p>
                    </div>
                  </div>

                  {/* Right Column: Code and Copy action */}
                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 bg-white border border-[#D89A1E]/20 p-2.5 rounded-2xl shadow-inner flex-1 max-w-md w-full">
                    <div className="flex flex-col justify-center px-4 py-1.5 flex-1 min-w-[140px] text-center sm:text-left">
                      <span className="text-[9px] uppercase tracking-widest font-extrabold text-[#7A8C3A]">Invite Code</span>
                      <span className="text-2xl font-mono font-black tracking-widest text-[#D89A1E] select-all mt-0.5">
                        {referralCode}
                      </span>
                    </div>
                    <button
                      onClick={handleCopy}
                      className={`flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl font-extrabold text-sm transition-all duration-300 active:scale-95 shadow-md flex-shrink-0 sm:w-auto ${
                        copied
                          ? "bg-emerald-600 hover:bg-emerald-700 text-white shadow-emerald-600/10"
                          : "bg-gradient-to-r from-[#D89A1E] to-[#B37B13] hover:from-[#E8B84A] hover:to-[#D89A1E] text-white shadow-[#D89A1E]/10"
                      }`}
                    >
                      {copied ? (
                        <>
                          <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                          </svg>
                          <span>Copied Code!</span>
                        </>
                      ) : (
                        <>
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 7.5V6.108c0-1.135.845-2.098 1.976-2.192.373-.03.748-.057 1.123-.08M15.75 18H18a2.25 2.25 0 0 0 2.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 0 0-1.123-.08M15.75 18.75v-1.875a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5A3.375 3.375 0 0 0 6.375 7.5H5.25m11.9-3.664A2.251 2.251 0 0 0 15 2.25h-1.5a2.251 2.251 0 0 0-2.15 1.586m5.8 0c.065.21.1.433.1.664v.75h-6V4.5c0-.231.035-.454.1-.664M6.75 7.5H4.875c-.621 0-1.125.504-1.125 1.125v12c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V16.5a9 9 0 0 0-9-9Z" />
                          </svg>
                          <span>Copy Invitation</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* CTA Section */}
            <div className="mt-8 space-y-4">
              <a
                href={getDownloadLink()}
                className="block w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-[#7A8C3A] to-[#697931] hover:from-[#899C44] hover:to-[#7A8C3A] text-white font-extrabold text-lg text-center transition-all duration-300 shadow-lg shadow-[#7A8C3A]/20 hover:shadow-[#7A8C3A]/30 transform hover:-translate-y-0.5 active:translate-y-0"
                style={{ fontFamily: "Outfit, sans-serif" }}
              >
                Download & Claim Your Seeds
              </a>
              
              <div className="flex flex-wrap items-center justify-center gap-6 pt-5 border-t border-[#7A8C3A]/10">
                <a 
                  href="https://apps.apple.com/app/sabiq-rewards" 
                  className="flex items-center gap-2 text-sm font-bold text-[#5C543A] hover:text-[#7A8C3A] transition-colors"
                >
                  <svg className="w-5 h-5 text-[#5C543A]" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.17c.66-.81 1.11-1.93.99-3.06-1 .04-2.21.67-2.93 1.49-.62.69-1.16 1.84-1.01 2.96 1.12.09 2.27-.57 2.95-1.39z"/>
                  </svg>
                  App Store
                </a>
                
                <a 
                  href="https://play.google.com/store/apps/details?id=com.example.noor_rewards" 
                  className="flex items-center gap-2 text-sm font-bold text-[#5C543A] hover:text-[#7A8C3A] transition-colors"
                >
                  <svg className="w-5 h-5 text-[#5C543A]" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M5.25 3.037a1.5 1.5 0 0 0-1.5 1.5v14.926a1.5 1.5 0 0 0 2.378 1.226l12.454-7.463a1.5 1.5 0 0 0 0-2.452L6.128 3.31A1.5 1.5 0 0 0 5.25 3.037Z" />
                  </svg>
                  Google Play Store
                </a>
              </div>
            </div>

          </div>
        </div>

        {/* Right Column: Sabiq Original App Home Dashboard Mockup */}
        <div className="lg:col-span-5 flex justify-center">
          
          {/* Smart Phone Device Frame Mockup */}
          <div className="w-[330px] h-[660px] rounded-[48px] border-[10px] border-[#2A2410] bg-[#FFFDF8] shadow-2xl relative flex flex-col overflow-hidden select-none">
            
            {/* Phone Speaker Notch */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 h-[22px] w-[140px] bg-[#2A2410] rounded-b-[20px] z-30 flex items-center justify-center">
              <div className="w-12 h-1 bg-neutral-800 rounded-full mb-1" />
            </div>

            {/* In-App Status Bar */}
            <div className="pt-7 px-6 flex justify-between items-center text-xs font-bold text-[#2A2410]/70 z-20">
              <span>9:41 AM</span>
              <div className="flex items-center gap-1.5">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9-4.03-9-9-9zm1 13.5h-2v-6h2v6zm0-8h-2V7h2v1.5z"/></svg>
                <span className="w-5 h-3 border border-[#2A2410]/70 rounded-[3px] p-[1px] flex"><span className="h-full w-full bg-[#2A2410] rounded-[1px]" /></span>
              </div>
            </div>

            {/* Sabiq Original App In-Header Layout */}
            <div className="px-5 pt-3 pb-3 flex justify-between items-center z-20 border-b border-[#7A8C3A]/10 bg-white">
              <div className="flex-1">
                <span className="text-[10px] uppercase font-semibold text-[#7A8C3A] tracking-wider block" style={{ fontFamily: "Outfit, sans-serif" }}>
                  Assalamu Alaikum
                </span>
                <h3 className="text-lg font-bold text-[#2A2410] leading-tight" style={{ fontFamily: "Outfit, sans-serif" }}>
                  Friend
                </h3>
              </div>
              <div className="flex items-center gap-2">
                {/* Notification Bell */}
                <div className="w-9 h-9 rounded-xl bg-white border border-slate-100 flex items-center justify-center relative shadow-sm">
                  <svg className="w-5 h-5 text-[#2A2410]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
                  </svg>
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white" />
                </div>
                {/* Profile Icon with Level Badge */}
                <div className="relative">
                  <div className="w-9 h-9 rounded-xl bg-[#E8B84A] flex items-center justify-center font-extrabold text-sm text-[#2A2410] border border-[#5C3A0A]/10 shadow-sm font-sans">
                    S
                  </div>
                  <span className="absolute -bottom-1 -right-1 bg-[#2A2410] text-[#FFC83D] text-[7.5px] font-black px-1.5 py-0.5 rounded-md border border-white" style={{ fontFamily: "Rajdhani, sans-serif" }}>
                    LV 3
                  </span>
                </div>
              </div>
            </div>

            {/* Sabiq Original App Screen Content (Scrollable) */}
            <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 bg-gradient-to-b from-[#FFFDF8] to-[#FFF9E6]">
              
              {/* 1. Sabiq _Y4HeroCard (Garden Card) */}
              <div className="bg-gradient-to-br from-[#FFFCEE] to-[#FFF9E2] border border-[#D89A1E]/30 rounded-2xl p-4 shadow-sm relative overflow-hidden flex flex-col justify-between h-[130px] group transition-all duration-200">
                {/* Sun Glow */}
                <div className="absolute -top-6 -right-6 w-20 h-20 bg-[#FFC83D]/25 rounded-full blur-xl animate-pulse" />
                
                <div className="flex items-center justify-between relative z-10">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 flex items-center justify-center filter drop-shadow-sm">
                      <SabiqCoin size={32} sprouting={true} />
                    </div>
                    <div>
                      <span className="text-[9px] uppercase tracking-widest font-extrabold text-[#7A8C3A]">Sabiq Seeds</span>
                      <div className="text-xl font-black text-[#2A2410] font-mono leading-none mt-0.5">
                        {seeds.toLocaleString()}
                      </div>
                    </div>
                  </div>
                  {/* Seeds Expiring alert */}
                  <div className="text-right">
                    <span className="inline-block text-[8px] bg-[#7A8C3A]/10 text-[#7A8C3A] font-extrabold px-2 py-0.5 rounded-full border border-[#7A8C3A]/15">
                      Sprout Status
                    </span>
                    <div className="text-[9px] font-semibold text-[#5C543A] mt-0.5 font-sans">
                      Level 3 · Growing
                    </div>
                  </div>
                </div>

                {/* Animated Seed Pop-up */}
                {showSeedBonus && (
                  <div className="absolute top-12 left-1/3 bg-[#7A8C3A] text-white text-[9px] font-black py-1.5 px-3 rounded-full animate-bounce shadow-md z-30">
                    +50 Seeds Bonus! 🎉
                  </div>
                )}

                {/* Micro Garden plants visual representing real garden */}
                <div className="mt-3 relative z-10 flex items-end justify-between px-2 pt-2 border-t border-[#D89A1E]/10">
                  {/* Curved grass slope */}
                  <div className="absolute inset-x-0 bottom-0 h-4 bg-[#7A8C3A]/10 rounded-b-xl blur-xs pointer-events-none" />
                  
                  {/* 5 plants representing daily progress stages */}
                  <div className="flex flex-col items-center gap-0.5">
                    <span className="text-xs transition-transform hover:scale-125">🌱</span>
                    <span className="text-[7px] text-[#5C543A] font-bold">Mon</span>
                  </div>
                  <div className="flex flex-col items-center gap-0.5">
                    <span className="text-xs transition-transform hover:scale-125">🌿</span>
                    <span className="text-[7px] text-[#5C543A] font-bold">Tue</span>
                  </div>
                  <div className="flex flex-col items-center gap-0.5">
                    <span className="text-xs transition-transform hover:scale-125">🪴</span>
                    <span className="text-[7px] text-[#5C543A] font-bold">Wed</span>
                  </div>
                  <div className="flex flex-col items-center gap-0.5 scale-110">
                    <span className="text-xs animate-bounce">🌸</span>
                    <span className="text-[7px] text-[#7A8C3A] font-black">Thu</span>
                  </div>
                  <div className="flex flex-col items-center gap-0.5 opacity-40">
                    <span className="text-xs">🌰</span>
                    <span className="text-[7px] text-[#5C543A] font-bold">Fri</span>
                  </div>
                </div>
              </div>

              {/* 2. Sabiq _Y4StreakCard (Habit Streak Plant Tracker) */}
              <div className="bg-white border border-[#7A8C3A]/15 rounded-2xl p-3 shadow-xs">
                <div className="flex justify-between items-center">
                  <div>
                    <span className="text-[9px] uppercase tracking-wider font-extrabold text-[#7A8C3A]">Habit Streak</span>
                    <h4 className="text-xs font-black text-[#2A2410] mt-0.5">5 Days Active!</h4>
                  </div>
                  <span className="text-[10px] font-black px-2 py-0.5 rounded bg-amber-500/10 text-amber-600 border border-amber-500/10">
                    🔥 5 Days
                  </span>
                </div>
                <div className="flex items-center justify-between gap-1.5 mt-2.5">
                  {[
                    { day: "S", active: true },
                    { day: "M", active: true },
                    { day: "T", active: true },
                    { day: "W", active: true },
                    { day: "T", active: true },
                    { day: "F", active: false },
                    { day: "S", active: false },
                  ].map((d, index) => (
                    <div key={index} className="flex-1 flex flex-col items-center p-1 rounded-lg border border-slate-100 bg-slate-50/50">
                      <span className={`text-[8px] font-bold ${d.active ? "text-[#7A8C3A]" : "text-slate-400"}`}>
                        {d.day}
                      </span>
                      <span className="text-[10px] mt-0.5">
                        {d.active ? "🌱" : "▫️"}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* 3. Today's Plots Title Section */}
              <div className="pt-1 flex items-center justify-between">
                <h4 className="text-xs font-extrabold italic text-[#2A2410] font-serif" style={{ fontFamily: "Outfit, sans-serif" }}>
                  Today's Plots
                </h4>
              </div>

              {/* 4. Sabiq Original Activity Grid (2x2 _ActivityCard Mockup) */}
              <div className="grid grid-cols-2 gap-3">
                {/* Grid Item 1: Quran Card */}
                <div className="bg-[#FFFDF6] border border-[#7A8C3A]/15 rounded-xl p-3 flex flex-col justify-between min-h-[110px] relative overflow-hidden transition-transform duration-200 active:scale-98">
                  <div>
                    <div className="flex justify-between items-start">
                      <span className="text-[14px]">📖</span>
                      <span className="text-[7px] font-black bg-[#7A8C3A]/10 text-[#7A8C3A] px-1.5 py-0.5 rounded">
                        +10/Verse
                      </span>
                    </div>
                    <h5 className="text-[11px] font-black text-[#2A2410] mt-2">Read Quran</h5>
                    <p className="text-[8px] text-[#5C543A] mt-0.5 leading-tight">Al-Mulk · Ayah 7 · +12 today</p>
                  </div>
                  <span className="text-[8px] text-[#7A8C3A] font-bold self-start mt-2">Continue →</span>
                </div>

                {/* Grid Item 2: Dhikr Card (INTERACTIVE counter) */}
                <div 
                  onClick={handleDhikrTap}
                  className="bg-[#FFFDF6] border border-[#D89A1E]/20 rounded-xl p-3 flex flex-col justify-between min-h-[110px] cursor-pointer relative overflow-hidden transition-all duration-200 active:scale-95 hover:border-[#D89A1E]/40"
                >
                  <div>
                    <div className="flex justify-between items-start">
                      <span className="text-[14px]">📿</span>
                      <span className="text-[7px] font-black bg-[#D89A1E]/10 text-[#D89A1E] px-1.5 py-0.5 rounded">
                        +5/Tap
                      </span>
                    </div>
                    <h5 className="text-[11px] font-black text-[#2A2410] mt-2">Daily Dhikr</h5>
                    <p className="text-[8px] text-[#5C543A] mt-0.5 leading-tight font-semibold text-[#D89A1E]">
                      {dhikrCount} / 33 · SubhanAllah
                    </p>
                  </div>
                  <span className="text-[8px] text-[#D89A1E] font-extrabold uppercase tracking-wide mt-2">
                    {dhikrCount >= 33 ? "Reset set 🔄" : "TAP TO REPEAT 👆"}
                  </span>
                </div>

                {/* Grid Item 3: Achievements Card */}
                <div className="bg-[#FFFDF6] border border-[#7A8C3A]/10 rounded-xl p-3 flex flex-col justify-between min-h-[110px] relative overflow-hidden">
                  <div>
                    <div className="flex justify-between items-start">
                      <span className="text-[14px]">🏆</span>
                      <span className="text-[7px] font-black bg-purple-500/10 text-purple-600 px-1.5 py-0.5 rounded">
                        Badges
                      </span>
                    </div>
                    <h5 className="text-[11px] font-black text-[#2A2410] mt-2">Achievements</h5>
                    <p className="text-[8px] text-[#5C543A] mt-0.5 leading-tight font-sans">Last: Fajr Warrior</p>
                  </div>
                  <span className="text-[8px] text-[#7A8C3A] font-bold self-start mt-2">View Badges →</span>
                </div>

                {/* Grid Item 4: Invite Friends Card */}
                <div className="bg-[#FFFDF6] border border-[#7A8C3A]/10 rounded-xl p-3 flex flex-col justify-between min-h-[110px] relative overflow-hidden">
                  <div>
                    <div className="flex justify-between items-start">
                      <span className="text-[14px]">🤝</span>
                      <span className="text-[7px] font-black bg-[#D89A1E]/10 text-[#D89A1E] px-1.5 py-0.5 rounded">
                        +500 Seeds
                      </span>
                    </div>
                    <h5 className="text-[11px] font-black text-[#2A2410] mt-2">Invite Friends</h5>
                    <p className="text-[8px] text-[#5C543A] mt-0.5 leading-tight font-sans">Earn per friend referred</p>
                  </div>
                  <span className="text-[8px] text-[#D89A1E] font-bold self-start mt-2">Share Link →</span>
                </div>
              </div>

            </div>

            {/* Sabiq Original App In-App Bottom Navigation Bar */}
            <div className="h-14 bg-white border-t border-[#7A8C3A]/10 flex items-center justify-around px-4 z-20 flex-shrink-0">
              <div className="flex flex-col items-center gap-0.5 text-[#7A8C3A] opacity-100">
                <span className="text-[15px]">🏡</span>
                <span className="text-[8px] font-extrabold uppercase tracking-wide">Home</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#2A2410] opacity-40">
                <span className="text-[15px]">📖</span>
                <span className="text-[8px] font-extrabold uppercase tracking-wide">Quran</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#2A2410] opacity-40">
                <span className="text-[15px]">📿</span>
                <span className="text-[8px] font-extrabold uppercase tracking-wide">Dhikr</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#2A2410] opacity-40">
                <span className="text-[15px]">🌱</span>
                <span className="text-[8px] font-extrabold uppercase tracking-wide">Impact</span>
              </div>
            </div>

          </div>

        </div>

      </div>

      {/* Features Overview Section: Displays exact English translations from app_en.arb */}
      <div className="w-full max-w-5xl mt-16 grid grid-cols-1 md:grid-cols-3 gap-6 z-10 px-4">
        
        {/* Card 1: Quran Companion */}
        <div className="bg-white/60 border border-[#7A8C3A]/10 rounded-2xl p-6 hover:shadow-md transition-shadow relative overflow-hidden group">
          <div className="w-10 h-10 rounded-xl bg-[#7A8C3A]/10 flex items-center justify-center mb-4 transition-transform duration-300 group-hover:scale-105">
            <svg className="w-5 h-5 text-[#7A8C3A]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <h3 className="font-black text-[#2A2410] text-lg" style={{ fontFamily: "Outfit, sans-serif" }}>Quran Companion</h3>
          <p className="text-sm text-[#5C543A] mt-2 leading-relaxed font-medium">
            The Quran is a guide for all of mankind. Unlock verses, daily duas, and reflections tailored for your journey. Earn +10 Sabiq Seeds per verse read.
          </p>
        </div>

        {/* Card 2: Daily Dhikr & Dua */}
        <div className="bg-white/60 border border-[#7A8C3A]/10 rounded-2xl p-6 hover:shadow-md transition-shadow relative overflow-hidden group">
          <div className="w-10 h-10 rounded-xl bg-[#FFC83D]/10 flex items-center justify-center mb-4 transition-transform duration-300 group-hover:scale-105">
            <svg className="w-5 h-5 text-[#D89A1E]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
            </svg>
          </div>
          <h3 className="font-black text-[#2A2410] text-lg" style={{ fontFamily: "Outfit, sans-serif" }}>Daily Dhikr & Dua</h3>
          <p className="text-sm text-[#5C543A] mt-2 leading-relaxed font-medium">
            A heart that remembers Allah finds peace in every breath. Recite morning and evening dhikr — and watch your reward unfold, hadith by hadith.
          </p>
        </div>

        {/* Card 3: Impactful Seeds */}
        <div className="bg-white/60 border border-[#7A8C3A]/10 rounded-2xl p-6 hover:shadow-md transition-shadow relative overflow-hidden group">
          <div className="w-10 h-10 rounded-xl bg-[#7A8C3A]/10 flex items-center justify-center mb-4 transition-transform duration-300 group-hover:scale-105">
            <div className="w-5 h-5 flex items-center justify-center">
              <SabiqCoin size={20} sprouting={true} />
            </div>
          </div>
          <h3 className="font-black text-[#2A2410] text-lg" style={{ fontFamily: "Outfit, sans-serif" }}>Impactful Seeds</h3>
          <p className="text-sm text-[#5C543A] mt-2 leading-relaxed font-medium">
            Sadaqah extinguishes sin as water extinguishes fire. Every Seed you earn becomes real food, real water, real hope for verified community humanitarian projects.
          </p>
        </div>
      </div>

      <footer className="mt-16 text-[#8E8770] text-xs relative z-10 text-center space-y-2 font-sans">
        <p>© {new Date().getFullYear()} Sabiq. All rights reserved.</p>
        <p className="opacity-80">Made with ❤️ for the Ummah.</p>
      </footer>
    </div>
  );
}

export default function JoinPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-[#FFFDF8] via-[#FFF9E6] to-[#FFF4D2] text-[#5C543A]">
        <div className="animate-pulse flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-[#7A8C3A]/10 border border-[#7A8C3A]/20 flex items-center justify-center shadow-sm">
            <svg className="w-8 h-8 text-[#7A8C3A] animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" />
            </svg>
          </div>
          <span className="font-semibold tracking-wider text-xs uppercase text-[#7A8C3A]">Loading invitation...</span>
        </div>
      </div>
    }>
      <JoinPageContent />
    </Suspense>
  );
}
