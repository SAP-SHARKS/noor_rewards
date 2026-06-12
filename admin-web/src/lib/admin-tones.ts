// Shared color tones for the admin portal.
//
// Each section of the dashboard owns one tone so the sidebar nav row, the
// top-bar chip, and the page content stay visually linked. Pick tones from
// the 50/100/700 ramp for light mode and 500-tinted overlays for dark mode
// to stay calm and readable.
//
// Pages can also use them ad-hoc for stat cards, pills, badges, status
// indicators, etc. — anywhere a colored hint adds meaning.

export type Tone =
  | "teal"
  | "amber"
  | "emerald"
  | "violet"
  | "sky"
  | "rose"
  | "indigo"
  | "fuchsia"
  | "orange"
  | "slate"
  | "cyan"
  | "lime"
  | "pink";

export interface ToneLight {
  bg: string;
  text: string;
  ring: string;
  dot: string;
  border: string;
}

export interface ToneDark {
  bg: string;
  text: string;
  ring: string;
  border: string;
}

export const TONE_LIGHT: Record<Tone, ToneLight> = {
  teal:    { bg: "bg-teal-50",    text: "text-teal-700",    ring: "ring-teal-200/70",    dot: "bg-teal-500",    border: "border-teal-100" },
  amber:   { bg: "bg-amber-50",   text: "text-amber-700",   ring: "ring-amber-200/70",   dot: "bg-amber-500",   border: "border-amber-100" },
  emerald: { bg: "bg-emerald-50", text: "text-emerald-700", ring: "ring-emerald-200/70", dot: "bg-emerald-500", border: "border-emerald-100" },
  violet:  { bg: "bg-violet-50",  text: "text-violet-700",  ring: "ring-violet-200/70",  dot: "bg-violet-500",  border: "border-violet-100" },
  sky:     { bg: "bg-sky-50",     text: "text-sky-700",     ring: "ring-sky-200/70",     dot: "bg-sky-500",     border: "border-sky-100" },
  rose:    { bg: "bg-rose-50",    text: "text-rose-700",    ring: "ring-rose-200/70",    dot: "bg-rose-500",    border: "border-rose-100" },
  indigo:  { bg: "bg-indigo-50",  text: "text-indigo-700",  ring: "ring-indigo-200/70",  dot: "bg-indigo-500",  border: "border-indigo-100" },
  fuchsia: { bg: "bg-fuchsia-50", text: "text-fuchsia-700", ring: "ring-fuchsia-200/70", dot: "bg-fuchsia-500", border: "border-fuchsia-100" },
  orange:  { bg: "bg-orange-50",  text: "text-orange-700",  ring: "ring-orange-200/70",  dot: "bg-orange-500",  border: "border-orange-100" },
  slate:   { bg: "bg-slate-100",  text: "text-slate-700",   ring: "ring-slate-200/70",   dot: "bg-slate-500",   border: "border-slate-200" },
  cyan:    { bg: "bg-cyan-50",    text: "text-cyan-700",    ring: "ring-cyan-200/70",    dot: "bg-cyan-500",    border: "border-cyan-100" },
  lime:    { bg: "bg-lime-50",    text: "text-lime-700",    ring: "ring-lime-200/70",    dot: "bg-lime-500",    border: "border-lime-100" },
  pink:    { bg: "bg-pink-50",    text: "text-pink-700",    ring: "ring-pink-200/70",    dot: "bg-pink-500",    border: "border-pink-100" },
};

export const TONE_DARK: Record<Tone, ToneDark> = {
  teal:    { bg: "bg-teal-500/15",    text: "text-teal-300",    ring: "ring-teal-400/30",    border: "border-teal-500/30" },
  amber:   { bg: "bg-amber-500/15",   text: "text-amber-300",   ring: "ring-amber-400/30",   border: "border-amber-500/30" },
  emerald: { bg: "bg-emerald-500/15", text: "text-emerald-300", ring: "ring-emerald-400/30", border: "border-emerald-500/30" },
  violet:  { bg: "bg-violet-500/15",  text: "text-violet-300",  ring: "ring-violet-400/30",  border: "border-violet-500/30" },
  sky:     { bg: "bg-sky-500/15",     text: "text-sky-300",     ring: "ring-sky-400/30",     border: "border-sky-500/30" },
  rose:    { bg: "bg-rose-500/15",    text: "text-rose-300",    ring: "ring-rose-400/30",    border: "border-rose-500/30" },
  indigo:  { bg: "bg-indigo-500/15",  text: "text-indigo-300",  ring: "ring-indigo-400/30",  border: "border-indigo-500/30" },
  fuchsia: { bg: "bg-fuchsia-500/15", text: "text-fuchsia-300", ring: "ring-fuchsia-400/30", border: "border-fuchsia-500/30" },
  orange:  { bg: "bg-orange-500/15",  text: "text-orange-300",  ring: "ring-orange-400/30",  border: "border-orange-500/30" },
  slate:   { bg: "bg-slate-500/20",   text: "text-slate-200",   ring: "ring-slate-400/30",   border: "border-slate-500/30" },
  cyan:    { bg: "bg-cyan-500/15",    text: "text-cyan-300",    ring: "ring-cyan-400/30",    border: "border-cyan-500/30" },
  lime:    { bg: "bg-lime-500/15",    text: "text-lime-300",    ring: "ring-lime-400/30",    border: "border-lime-500/30" },
  pink:    { bg: "bg-pink-500/15",    text: "text-pink-300",    ring: "ring-pink-400/30",    border: "border-pink-500/30" },
};

export function tone(t: Tone, dark: boolean) {
  return dark ? TONE_DARK[t] : TONE_LIGHT[t];
}
