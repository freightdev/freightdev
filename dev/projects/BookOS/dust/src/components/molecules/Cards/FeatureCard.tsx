// apps/web/components/ui/molecules/cards/FeatureCard.tsx
// FeatureCard.tsx

'use client'

import type { Feature } from '@web/components/types/features'
import { iconMap } from '@web/components/utils/iconMap'
import type { LucideIcon } from 'lucide-react'

const FeatureCard = ({
  title,
  description,
  tagline,
  icon,
  status,
}: Feature) => {
  const Icon: LucideIcon = iconMap[icon]

  const badge = {
    live: null,
    beta: (
      <span className="text-xs text-yellow-400 bg-yellow-900/30 px-2 py-0.5 rounded-full">
        Beta
      </span>
    ),
    'coming-soon': (
      <span className="text-xs text-purple-300 bg-purple-900/30 px-2 py-0.5 rounded-full">
        Coming Soon
      </span>
    ),
  }[status]

  return (
    <li className="relative flex flex-col gap-4 bg-black/70 border border-gray-700 p-6 rounded-2xl shadow-md hover:shadow-purple-600/10 transition">
      <div className="flex justify-between items-start">
        <div className="flex items-center gap-3">
          <span className="text-purple-400">
            <Icon size={24} />
          </span>
          <h3 className="text-lg font-semibold text-white">{title}</h3>
        </div>
        {badge}
      </div>

      <p className="text-sm text-gray-400">{description}</p>
      {tagline && <p className="text-xs text-purple-400 italic">{tagline}</p>}
    </li>
  )
}

export default FeatureCard
