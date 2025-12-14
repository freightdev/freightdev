// packages/ui/src/components/web/Marketing/PoweringSession.tsx

'use client'

export function PoweringSession() {
  const logos = [
    { name: 'OpenHWY', color: 'text-pink-400', tagline: 'Transparent infrastructure for the freight future.' },
    { name: 'MARK', color: 'text-purple-400', tagline: 'Markdown Agent Routing Kernel powering real-time agents.' },
    { name: 'CoDriver', color: 'text-blue-400', tagline: 'Your on-call terminal AI — always synced, always sharp.' },
  ]

  return (
    <section
      id="powering"
      className="w-full px-6 py-20 bg-[#0f001c] text-white border-t border-white/10"
    >
      <div className="flex flex-col items-center max-w-5xl gap-6 mx-auto text-center">
        <h2 className="text-2xl font-semibold sm:text-3xl">
          Powered by the future of freight.
        </h2>
        <p className="max-w-xl text-base text-white/60 sm:text-lg">
          Built on bleeding-edge AI systems and open logistics protocols.
        </p>

        <div className="grid w-full grid-cols-1 gap-6 mt-8 sm:grid-cols-3">
          {logos.map((platform, idx) => (
            <div
              key={idx}
              className="p-5 text-left transition border shadow-sm bg-white/5 hover:bg-white/10 rounded-xl border-white/10"
            >
              <h3 className={`text-lg font-bold mb-1 ${platform.color}`}>
                {platform.name}
              </h3>
              <p className="text-sm text-white/70">{platform.tagline}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
