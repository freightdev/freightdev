// packages/ui/src/components/web/Marketing/DemoSession.tsx

'use client'

import Link from 'next/link'

export function DemoSession() {
  return (
    <section
      id="demo"
      className="w-full px-6 py-24 bg-gradient-to-b from-[#150025] via-[#210034] to-[#2a0040] text-white"
    >
      <div className="flex flex-col items-center max-w-5xl gap-6 mx-auto text-center">
        <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
          See it in action.
        </h2>
        <p className="max-w-2xl text-base text-white/70 sm:text-lg">
          Watch how PacketPilot auto-fills broker packets. See CargoConnect scrape load boards.
          And follow real dispatcher workflows in a live AI-powered dashboard.
        </p>

        <div className="flex flex-wrap justify-center gap-4 mt-6">
          <Link
            href="/demo"
            className="px-6 py-3 text-sm font-semibold text-white transition bg-pink-500 rounded-full hover:bg-pink-400"
          >
            Launch Live Demo
          </Link>
          <Link
            href="/showcase"
            className="px-6 py-3 text-sm font-semibold text-white transition border rounded-full border-white/30 hover:bg-white/10"
          >
            View Showcase
          </Link>
        </div>

        {/* Optional: video or screenshot area */}
        <div className="flex items-center justify-center w-full max-w-4xl mt-12 text-sm border aspect-video bg-white/5 border-white/10 rounded-xl text-white/50">
          [ Product preview coming soon ]
        </div>
      </div>
    </section>
  )
}
