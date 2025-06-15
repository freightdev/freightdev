// apps/web/components/ui/molecules/cards/PlanCard.tsx
// PlanCard.tsx

import type { PlanCardProps } from '@web/components/types/plan'

export default function PlanCard({
  name,
  price,
  description,
  features,
  cta,
  billing,
}: PlanCardProps) {
  return (
    <div className="bg-black/60 backdrop-blur-md rounded-3xl p-8 shadow-xl border border-gray-700 hover:scale-[1.02] transition-transform">
      <div className="text-purple-400 font-semibold mb-2">{name}</div>
      <h3 className="text-3xl font-bold text-white mb-4">
        ${billing === 'monthly' ? price.monthly : price.annual}
      </h3>
      <p className="text-gray-400 mb-6">{description}</p>
      <ul className="text-sm text-white space-y-2 mb-6">
        {features.map((feature, i) => (
          <li key={i} className="flex items-start gap-2">
            <span className="text-green-400 font-bold">✓</span>
            <span>{feature}</span>
          </li>
        ))}
      </ul>
      <button className="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 rounded-full font-semibold transition">
        {cta}
      </button>
    </div>
  )
}
