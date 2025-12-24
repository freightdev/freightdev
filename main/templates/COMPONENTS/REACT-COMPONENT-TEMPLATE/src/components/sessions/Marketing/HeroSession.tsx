// packages/ui/src/components/web/Marketing/HeroSession.tsx

'use client'

import Link from 'next/link'

export function HeroSession() {
  return (
    <section
      id="hero"
      className="relative z-10 w-full min-h-screen flex items-center justify-center px-6 pt-28 pb-24 text-center bg-gradient-to-br from-[#120026] via-[#1f002f] to-[#2a0040] text-white"
    >
      <div className="flex flex-col items-center max-w-4xl gap-6 mx-auto">
        <h1 className="text-4xl font-bold leading-tight tracking-tight sm:text-5xl md:text-6xl">
          Fast. Easy. <span className="text-pink-400">Dispatching</span>.
        </h1>
        <p className="max-w-2xl text-base sm:text-lg md:text-xl text-white/70">
          Built by truckers, for truckers. No bloat. Just tools that get you booked, paid, and back on the road.
        </p>
        <div className="flex flex-wrap justify-center gap-4 mt-6">
          <Link
            href="/signup"
            className="px-6 py-3 text-sm font-semibold text-black transition bg-white rounded-full hover:bg-pink-200"
          >
            Get Started Free
          </Link>
          <Link
            href="/demo"
            className="px-6 py-3 text-sm font-semibold text-white transition border rounded-full border-white/30 hover:bg-white/10"
          >
            Live Demo
          </Link>
        </div>
      </div>

      {/* Background Glow */}
      <div className="absolute inset-0 overflow-hidden -z-10">
        <div className="absolute top-1/2 left-1/2 w-[200%] h-[200%] -translate-x-1/2 -translate-y-1/2 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-pink-500/10 via-purple-800/10 to-transparent blur-3xl opacity-30" />
      </div>
    </section>
  )
}
