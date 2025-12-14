// packages/ui/src/components/web/Marketing/PricingSession.tsx

'use client'

export function PricingSession() {
  const plans = [
    {
      name: 'Starter',
      price: '$0',
      description: 'For new dispatchers testing the waters.',
      features: [
        'Access 3 free tools',
        'Community support',
        'Basic analytics',
        'Limited packet fills',
      ],
    },
    {
      name: 'Pro',
      price: '$29/mo',
      description: 'Built for solo dispatchers who want speed.',
      features: [
        'Unlimited tool access',
        'Live rate data',
        'AI email scanner',
        'PacketPilot + CargoConnect',
      ],
      highlight: true,
    },
    {
      name: 'Boss',
      price: '$99/mo',
      description: 'For multi-driver dispatchers and small teams.',
      features: [
        'Multi-client dashboard',
        'Team load tracking',
        'Role-based tools',
        'Premium support & onboarding',
      ],
    },
  ]

  return (
    <section
      id="pricing"
      className="w-full px-6 py-24 bg-gradient-to-b from-[#180028] via-[#220036] to-[#2a0040] text-white"
    >
      <div className="max-w-6xl mx-auto text-center">
        <h2 className="mb-4 text-3xl font-bold sm:text-4xl">Simple pricing for serious dispatchers.</h2>
        <p className="max-w-2xl mx-auto mb-12 text-base text-white/70 sm:text-lg">
          No contracts. No hidden fees. Scale your dispatch business one load at a time.
        </p>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
          {plans.map((plan, idx) => (
            <div
              key={idx}
              className={`rounded-xl p-6 border border-white/10 transition ${
                plan.highlight
                  ? 'bg-pink-500/10 border-pink-400'
                  : 'bg-white/5 hover:bg-white/10'
              }`}
            >
              <h3 className="mb-1 text-xl font-semibold">{plan.name}</h3>
              <p className="mb-2 text-3xl font-bold">{plan.price}</p>
              <p className="mb-4 text-sm text-white/70">{plan.description}</p>
              <ul className="flex flex-col gap-2 mb-6 text-sm text-white/80">
                {plan.features.map((feature, i) => (
                  <li key={i}>• {feature}</li>
                ))}
              </ul>
              <button
                className={`w-full py-2 rounded-full text-sm font-semibold transition ${
                  plan.highlight
                    ? 'bg-pink-500 text-white hover:bg-pink-400'
                    : 'border border-white/30 text-white hover:bg-white/10'
                }`}
              >
                {plan.price === '$0' ? 'Start Free' : 'Choose Plan'}
              </button>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
