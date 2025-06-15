// apps/web/components/nav/FloatingNavbar.tsx
// FloatingNavbar.tsx

import Link from 'next/link'

export const FloatingNavbar = () => {
  return (
    <div className="relative z-50">
      <div className="fixed top-4 left-1/2 transform -translate-x-1/2 w-[90%] max-w-6xl px-6 py-3 bg-white/10 backdrop-blur-sm border border-white/10 rounded-full shadow-none">
        <div className="flex justify-between items-center w-full">
          {/* Logo and Subtext in Row */}
          <div className="flex items-center gap-4">
            <h1 className="text-base font-semibold tracking-widest uppercase text-white">
              <Link href="/">FED</Link>
            </h1>

            <p className="text-[10px] leading-tight tracking-wide text-white/40 italic">
              Fast and Easy Dispatching LLC · Powered by{' '}
              <span className="text-pink-400">OpenHWY</span> and{' '}
              <span className="text-purple-400">ELDA</span>
            </p>
          </div>

          {/* Nav Links */}
          <nav className="flex items-center gap-5 text-sm font-medium text-white">
            <Link
              href="#features"
              scroll={true}
              className="hover:text-pink-400"
            >
              Features
            </Link>
            <Link href="#pricing" scroll={true} className="hover:text-pink-400">
              Pricing
            </Link>
            <Link
              href="#showcase"
              scroll={true}
              className="hover:text-pink-400"
            >
              Showcase
            </Link>
            <Link href="/docs" className="hover:text-pink-400">
              Docs
            </Link>

            {/* Dropdown */}
            <div className="relative group">
              <button className="hover:text-pink-400">Free Tools ▾</button>
              <ul className="absolute hidden group-hover:block bg-[#2a0040] mt-2 rounded-md shadow-lg py-2 w-44 text-sm text-white z-50">
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#mark">MARK Kernel/CLI</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#elda">ELDA AI Assistant</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#RateChecker">Rate Checker</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#DeadheadChecker">Deadhead Checker</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#LicenseChecker">License Checker</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#FEDChecker">FED Checker</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#MarketeerChecker">Marketeer Checker</Link>
                </li>
                <li className="px-4 py-2 hover:bg-purple-800 rounded">
                  <Link href="#FEDCheck">FED Checker</Link>
                </li>
              </ul>
            </div>

            {/* Right Buttons */}
            <Link
              href="/register"
              className="px-4 py-1 border border-white/30 rounded-full hover:bg-white hover:text-black transition"
            >
              Sign Up
            </Link>
            <Link
              href="/preview"
              className="px-4 py-1 rounded-full bg-pink-500 hover:bg-pink-400 text-white transition"
            >
              Live Preview
            </Link>
          </nav>
        </div>
      </div>
    </div>
  )
}
export default FloatingNavbar;