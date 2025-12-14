// packages/ui/src/components/web/Marketing/FeaturesSession.tsx

'use client'

export function FeaturesSession() {
  const features = [
    {
      title: 'Instant Packet Filling',
      description: 'Auto-complete broker packets, carrier setup, and compliance forms with one click.',
    },
    {
      title: 'Live Rate Check',
      description: 'Compare rates across load boards in real time and catch underpriced loads before they hit.',
    },
    {
      title: 'License & Compliance Checker',
      description: 'Instantly verify your authority, MC, DOT, and insurance against broker requirements.',
    },
    {
      title: 'Deadhead Calculator',
      description: 'Map and minimize deadhead miles using real-time location and market lanes.',
    },
    {
      title: 'AI-Powered Email Scanner',
      description: 'Scan load offers, extract key details, and sort by rate-per-mile automatically.',
    },
    {
      title: 'One-Tap Dispatch Flow',
      description: 'Send rate confirmations, packets, and updates in a unified dispatch command center.',
    },
  ]

  return (
    <section
      id="features"
      className="w-full px-6 py-24 bg-gradient-to-b from-[#140028] via-[#1e0035] to-[#2a0040] text-white"
    >
      <div className="max-w-6xl mx-auto text-center">
        <h2 className="mb-4 text-3xl font-bold sm:text-4xl">Features that move freight — fast.</h2>
        <p className="max-w-2xl mx-auto mb-12 text-base text-white/70 sm:text-lg">
          Every tool was built to reduce clicks, cut confusion, and help dispatchers win more loads without wasting time.
        </p>

        <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="p-6 text-left transition border shadow-sm bg-white/5 hover:bg-white/10 rounded-xl border-white/10"
            >
              <h3 className="mb-2 text-lg font-semibold text-pink-400">{feature.title}</h3>
              <p className="text-sm text-white/80">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
