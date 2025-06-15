// apps/web/components/ui/grids/FeatureGrid.tsx
// FeatureGrid.tsx

'use client'

import { features } from '@web/components/config/features.config'
import FeatureCard from '../cards/FeatureCard'

const FeatureGrid = () => {
  return (
    <section
      id="features"
      className="relative py-24 overflow-hidden bg-gradient-to-br from-gray-900 to-black"
    >
      <div className="absolute inset-0 bg-[radial-gradient(#ffffff0d_1px,transparent_1px)] [background-size:20px_20px] opacity-10 pointer-events-none z-0" />
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h2 className="text-4xl font-semibold text-center text-white mb-6">
          Features
        </h2>
        <p className="text-center text-gray-400 mb-12 max-w-2xl mx-auto">
          Features marked{' '}
          <span className="text-yellow-400 font-medium">Beta</span> are
          available to Veteran & Boss members. <span className="mx-1">|</span>
          <span className="text-purple-300 font-medium">Coming Soon</span>{' '}
          features are in active development and will unlock over time.
        </p>

        <ul className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <FeatureCard
              key={index}
              title={feature.title}
              description={feature.description}
              tagline={feature.tagline}
              icon={feature.icon}
              status={feature.status}
            />
          ))}
        </ul>
      </div>
    </section>
  )
}

export default FeatureGrid
