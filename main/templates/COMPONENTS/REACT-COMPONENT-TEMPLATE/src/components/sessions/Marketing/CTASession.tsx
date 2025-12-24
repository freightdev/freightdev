// packages/ui/src/components/web/Marketing/CTASession.tsx

'use client'

import Link from 'next/link'

export function CTASession() {
  return (
    <section
      id="cta"
      className="relative w-full px-6 py-24 bg-gradient-to-br from-[#1a0030] via-[#2a0040] to-black text-white text-center"
    >
      <div className="flex flex-col items-center max-w-3xl gap-6 mx-auto">
        <h2 className="text-3xl font-bold leading-tight tracking-tight sm:text-4xl">
          Ready to dispatch faster?
        </h2>
        <p className="max-w-xl text-base sm:text-lg text-white/70">
          Sign up in seconds and start using our tools with zero contracts, no commitment, and full support from real people.
        </p>
        <div className="flex flex-wrap justify-center gap-4 mt-4">
          <Link
            href="/signup"
            className="px-6 py-3 text-sm font-semibold text-white transition bg-pink-500 rounded-full hover:bg-pink-400"
          >
            Get Started
          </Link>
          <Link
            href="/contact"
            className="px-6 py-3 text-sm font-semibold text-white transition border rounded-full border-white/30 hover:bg-white/10"
          >
            Talk to Us
          </Link>
        </div>
      </div>

      {/* Optional background blur glow */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-pink-500/10 via-purple-700/10 to-transparent blur-3xl opacity-20" />
      </div>
    </section>
  )
}
