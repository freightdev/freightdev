// apps/web/components/ui/molecules/BadgeCard.tsx
// BadgeCard.tsx

'use client'

import type { BadgeConfig } from '@web/components/types/badge'

interface BadgeCardProps {
  badge: BadgeConfig
}

export default function BadgeCard({ badge }: BadgeCardProps) {
  return (
    <div
      className={`bg-black/80 backdrop-blur-md rounded-3xl p-8 shadow-xl border ${badge.color} hover:scale-[1.02] transition-transform`}
    >
      <div className="text-purple-400 font-semibold mb-2">
        {badge.name} Badge
      </div>
      <h3 className="text-3xl font-bold text-white mb-4">${badge.price}</h3>
      <p className="text-green-400 text-sm mb-2">{badge.discount}</p>
      <ul className="text-sm text-white space-y-2 mb-6">
        {badge.perks.map((perk, i) => (
          <li key={i} className="flex items-start gap-2">
            <span className="text-green-400 font-bold">✓</span>
            <span>{perk}</span>
          </li>
        ))}
      </ul>
      <button className="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 rounded-full font-semibold transition">
        Get {badge.name} Badge
      </button>
    </div>
  )
}
