"use client";

import React from "react";

interface SabiqLogoProps {
  size?: number;
  sprouting?: boolean;
  className?: string;
}

export default function SabiqLogo({ size = 40, sprouting = false, className = "" }: SabiqLogoProps) {
  const dots = [];
  // 12 dots evenly spaced at gold orbit radius = 76 (86 - 10)
  for (let i = 0; i < 12; i++) {
    const angle = -Math.PI / 2 + i * ((Math.PI * 2) / 12);
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
        {/* Radial gradient for the outer gold ring */}
        <radialGradient id="sabiqGold" cx="35%" cy="30%" r="80%">
          <stop offset="0%" stopColor="#FFE89A" />
          <stop offset="55%" stopColor="#E8B84A" />
          <stop offset="100%" stopColor="#8B6420" />
        </radialGradient>
        {/* Radial gradient for the emerald center */}
        <radialGradient id="sabiqEmerald" cx="35%" cy="30%" r="80%">
          <stop offset="0%" stopColor="#7FCFA8" />
          <stop offset="50%" stopColor="#4A9B8E" />
          <stop offset="100%" stopColor="#1F4F3D" />
        </radialGradient>
        {/* Linear gradient for the S gold lettering */}
        <linearGradient id="sabiqSGold" x1="20%" y1="0%" x2="80%" y2="100%">
          <stop offset="0%" stopColor="#FFFAEC" />
          <stop offset="50%" stopColor="#FFD662" />
          <stop offset="100%" stopColor="#A37520" />
        </linearGradient>
        {/* Linear gradient for the sprouting leaf */}
        <linearGradient id="sabiqLeaf" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#A8E0C5" />
          <stop offset="100%" stopColor="#4A9B8E" />
        </linearGradient>
      </defs>

      {/* Outer gold ring */}
      <circle cx="90" cy="90" r="86" fill="url(#sabiqGold)" stroke="#5C3A0A" strokeWidth="2.5" />
      
      {/* 12 decorative orbit dots */}
      <g fill="#5C3A0A" opacity="0.5">
        {dots}
      </g>

      {/* Gold highlight on ring */}
      <ellipse cx="60" cy="55" rx="22" ry="12" fill="#FFFAEC" opacity="0.5" />

      {/* Emerald center */}
      <circle cx="90" cy="90" r="62" fill="url(#sabiqEmerald)" stroke="#1F4F3D" strokeWidth="1.5" />

      {/* Emerald highlight */}
      <ellipse cx="72" cy="72" rx="20" ry="11" fill="#A8E0C5" opacity="0.5" />
      <circle cx="115" cy="115" r="2.5" fill="#FFFAEC" opacity="0.6" />

      {/* Sprouting Leaf (Option 04 detail layered on top if requested) */}
      {sprouting && (
        <g transform="translate(110, 42) rotate(25)">
          <path d="M 0 0 Q 12 -3 14 -10 Q 8 -8 0 0 Z" fill="url(#sabiqLeaf)" stroke="#1F4F3D" strokeWidth="1.5" />
          <path d="M 1 -1 Q 8 -5 12 -8" stroke="#1F4F3D" stroke-width="0.5" fill="none" />
        </g>
      )}

      {/* Bold italic serif S (Option 01 style) */}
      <text
        x="90"
        y="125"
        fontFamily="Fraunces, serif"
        fontSize="100"
        fontWeight="800"
        fill="url(#sabiqSGold)"
        textAnchor="middle"
        style={{ fontStyle: "italic", userSelect: "none" }}
        stroke="#5C3A0A"
        strokeWidth="1.2"
      >
        S
      </text>

      {/* Highlight sheen overlay on the S */}
      <text
        x="90"
        y="125"
        fontFamily="Fraunces, serif"
        fontSize="100"
        fontWeight="800"
        fill="#FFFAEC"
        textAnchor="middle"
        style={{ fontStyle: "italic", userSelect: "none", pointerEvents: "none" }}
        opacity="0.25"
      >
        S
      </text>
    </svg>
  );
}
