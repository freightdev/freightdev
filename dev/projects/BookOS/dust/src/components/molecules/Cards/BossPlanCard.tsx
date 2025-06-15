// apps/web/components/ui/molecules/BossPlanCard.tsx
// BossPlanCard.tsx

import type { PlanCardProps } from '@web/components/types/plan'
import Link from 'next/link'

export default function BossPlanCard({
  name,
  price,
  description,
  features,
  billing,
}: PlanCardProps) {
  return (
    <div className="bg-black/80 backdrop-blur-md border border-purple-700 rounded-3xl p-10 shadow-2xl text-white relative overflow-hidden hover:ring-2 hover:ring-purple-500/40 hover:scale-[1.01] transition">
      <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-purple-600/60 via-purple-500/20 to-transparent rounded-b-3xl" />
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 relative z-10">
        <div>
          <div className="text-purple-400 font-semibold mb-1">{name} Plan</div>
          <h3 className="text-4xl font-bold mb-2">
            ${billing === 'monthly' ? price.monthly : price.annual}+{' '}
            <span className="text-gray-400 text-sm">(Custom)</span>
          </h3>
          <p className="text-gray-400 mb-4">{description}</p>
          <Link
            href="/contact"
            className="inline-block bg-purple-600 hover:bg-purple-500 text-white font-semibold px-6 py-2 rounded-full shadow-lg transition"
          >
            Contact sales
          </Link>
        </div>
        <div className="text-sm text-white">
          <p className="text-purple-300 uppercase font-bold mb-2">Features</p>
          <ul className="space-y-1">
            {features.map((feature, i) => (
              <li key={i} className="flex items-start gap-2">
                <span className="text-green-400 font-bold">✓</span>
                <span>{feature}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )
}
