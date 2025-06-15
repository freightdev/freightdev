// apps/web/components/ui/molecules/cards/AgentCard.tsx
// AgentCard.tsx

'use client'

import type { ShowcaseAgent } from '@web/components/types/showcase'

type AgentCardProps = ShowcaseAgent

export default function AgentCard({
  title,
  description,
  icon: Icon,
}: AgentCardProps) {
  return (
    <div className="bg-gray-900 p-6 rounded-xl shadow-lg hover:ring-1 hover:ring-purple-500 transition-all duration-200">
      <div className="flex items-center gap-4 mb-4">
        <Icon className="text-purple-500 text-2xl" />
        <h2 className="text-xl font-bold text-white">{title}</h2>
      </div>
      <p className="text-gray-400 text-sm">{description}</p>
    </div>
  )
}
