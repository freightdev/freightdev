// apps/web/components/ui/molecules/cards/LinkCard.tsx
// LinkCard.tsx

import Link from 'next/link'
import type { ShowcaseLink } from '@web/components/types/showcase'

const LinkCard = ({ title, description, href, cta }: ShowcaseLink) => {
  return (
    <div className="bg-gray-800 hover:bg-gray-700 transition-all duration-200 p-6 rounded-xl shadow-md">
      <h3 className="text-lg font-semibold mb-2 text-white">{title}</h3>
      <p className="text-sm text-gray-400 mb-3">{description}</p>
      <Link
        href={href}
        className="text-purple-400 text-sm font-medium hover:underline"
      >
        {cta}
      </Link>
    </div>
  )
}

export default LinkCard
