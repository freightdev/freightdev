// packages/ui/src/components/web/Marketing/SponsorSession.tsx

'use client'

export function SponsorSession() {
  const sponsors = [
    {
      name: 'DAT',
      logo: '/sponsors/dat-logo.svg',
      url: 'https://www.dat.com/',
    },
    {
      name: 'TruckStop',
      logo: '/sponsors/truckstop-logo.svg',
      url: 'https://truckstop.com/',
    },
    {
      name: 'OpenHWY',
      logo: '/sponsors/openhwy-logo.svg',
      url: 'https://openhwy.ai/',
    },
    {
      name: 'MARK',
      logo: '/sponsors/mark-logo.svg',
      url: 'https://openhwy.ai/mark',
    },
  ]

  return (
    <section
      id="sponsors"
      className="w-full px-6 py-20 bg-[#10001e] text-white border-t border-white/10"
    >
      <div className="flex flex-col items-center max-w-5xl gap-6 mx-auto text-center">
        <h2 className="text-lg font-semibold tracking-wider uppercase sm:text-xl text-white/70">
          Trusted by industry leaders and innovators
        </h2>

        <div className="grid items-center w-full grid-cols-2 gap-6 mt-4 sm:grid-cols-4 justify-items-center">
          {sponsors.map((sponsor, idx) => (
            <a
              key={idx}
              href={sponsor.url}
              target="_blank"
              rel="noopener noreferrer"
              className="transition opacity-80 hover:opacity-100"
            >
              <img
                src={sponsor.logo}
                alt={`${sponsor.name} logo`}
                className="w-auto h-10"
              />
            </a>
          ))}
        </div>
      </div>
    </section>
  )
}
