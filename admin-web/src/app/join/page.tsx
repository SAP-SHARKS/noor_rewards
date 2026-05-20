"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";

function JoinPageContent() {
  const searchParams = useSearchParams();
  const referralCode = searchParams.get("ref") || "";

  const [copied, setCopied] = useState(false);
  const [os, setOs] = useState<"ios" | "android" | "other">("other");

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

  const getDownloadLink = () => {
    if (os === "ios") {
      return "https://apps.apple.com/app/sabiq-rewards"; // Update with real App Store URL
    }
    return "https://play.google.com/store/apps/details?id=com.example.noor_rewards"; // Update with real Play Store URL
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-radial from-indigo-950 via-slate-950 to-black text-white px-4 relative overflow-hidden font-sans">
      {/* Dynamic ambient backgrounds */}
      <div className="absolute top-[-20%] left-[-20%] w-[60%] h-[60%] rounded-full bg-violet-600/10 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-20%] w-[60%] h-[60%] rounded-full bg-amber-500/5 blur-[120px] pointer-events-none" />

      {/* Main card */}
      <div className="w-full max-w-md bg-slate-900/60 backdrop-blur-xl border border-violet-500/20 rounded-3xl p-8 text-center shadow-2xl relative z-10">
        
        {/* Glow ornament */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 w-32 h-1 bg-gradient-to-r from-transparent via-amber-400 to-transparent blur-[2px]" />

        {/* Logo/Icon */}
        <div className="mx-auto w-20 h-20 rounded-2xl bg-gradient-to-br from-violet-600 to-indigo-800 flex items-center justify-center shadow-lg shadow-violet-500/20 mb-6">
          <svg className="w-12 h-12 text-amber-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
          </svg>
        </div>

        <h1 className="text-3xl font-extrabold tracking-tight bg-gradient-to-r from-white via-indigo-200 to-amber-200 bg-clip-text text-transparent">
          You've Been Invited!
        </h1>
        
        <p className="text-slate-400 text-sm mt-3 px-2 leading-relaxed">
          Join <span className="text-violet-300 font-semibold">Sabiq / Noor Rewards</span> to walk the path of light, track your daily Quran & Dhikr, and earn rewarding Seeds.
        </p>

        {/* Referral Section */}
        {referralCode && (
          <div className="mt-8 p-5 bg-violet-950/30 border border-violet-500/20 rounded-2xl relative overflow-hidden group">
            <div className="absolute inset-0 bg-gradient-to-r from-violet-600/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <p className="text-xs text-violet-300 uppercase tracking-widest font-semibold">Your Referral Code</p>
            <div className="mt-2 flex items-center justify-center gap-3">
              <span className="text-2xl font-mono font-black tracking-wider text-amber-300">
                {referralCode}
              </span>
              <button 
                onClick={handleCopy}
                className="p-2 rounded-lg bg-slate-800/80 hover:bg-slate-700/80 text-slate-300 hover:text-white transition-colors focus:outline-none focus:ring-2 focus:ring-violet-500"
                title="Copy code"
              >
                {copied ? (
                  <svg className="w-5 h-5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15.666 3.888A2.25 2.25 0 0 0 13.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 0 1-.75.75H9a.75 0 0 1-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 0 1-2.25 2.25H6.75A2.25 2.25 0 0 1 4.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 0 1 1.927-.184" />
                  </svg>
                )}
              </button>
            </div>
            <p className="text-slate-400 text-xs mt-2">
              Use this code during signup to get <span className="text-amber-400 font-bold">500 free Seeds</span>!
            </p>
          </div>
        )}

        {/* CTA Section */}
        <div className="mt-8 space-y-3">
          <a
            href={getDownloadLink()}
            className="block w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-bold text-center transition-all duration-300 shadow-lg shadow-amber-500/20 hover:shadow-amber-500/30 transform hover:-translate-y-0.5 active:translate-y-0"
          >
            Download & Get Started
          </a>
          
          <div className="flex items-center justify-center gap-6 pt-4 border-t border-slate-800">
            <a 
              href="https://apps.apple.com/app/sabiq-rewards" 
              className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-white transition-colors"
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.17c.66-.81 1.11-1.93.99-3.06-1 .04-2.21.67-2.93 1.49-.62.69-1.16 1.84-1.01 2.96 1.12.09 2.27-.57 2.95-1.39z"/>
              </svg>
              App Store
            </a>
            
            <a 
              href="https://play.google.com/store/apps/details?id=com.example.noor_rewards" 
              className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-white transition-colors"
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M5.25 3.037a1.5 1.5 0 0 0-1.5 1.5v14.926a1.5 1.5 0 0 0 2.378 1.226l12.454-7.463a1.5 1.5 0 0 0 0-2.452L6.128 3.31A1.5 1.5 0 0 0 5.25 3.037Z" />
              </svg>
              Google Play
            </a>
          </div>
        </div>

      </div>

      <footer className="mt-8 text-slate-500 text-xs relative z-10">
        © {new Date().getFullYear()} Sabiq / Noor Rewards. All rights reserved.
      </footer>
    </div>
  );
}

export default function JoinPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-slate-950 text-slate-400">
        Loading invitation...
      </div>
    }>
      <JoinPageContent />
    </Suspense>
  );
}
