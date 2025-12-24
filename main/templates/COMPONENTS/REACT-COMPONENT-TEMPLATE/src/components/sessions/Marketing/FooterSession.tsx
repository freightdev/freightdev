// packages/ui/src/components/web/Marketing/FooterSession.tsx

'use client'

import Link from 'next/link'

export function FooterSession() {
  return (
    <footer className="w-full px-6 py-12 text-white bg-black border-t border-white/10">
      <div className="grid max-w-6xl grid-cols-1 gap-8 mx-auto text-sm sm:grid-cols-3">
        {/* Column 1 */}
        <div className="flex flex-col gap-2">
          <h3 className="font-semibold text-white/80">Company</h3>
          <Link href="/about" className="text-white/60 hover:text-white">About</Link>
          <Link href="/contact" className="text-white/60 hover:text-white">Contact</Link>
          <Link href="/careers" className="text-white/60 hover:text-white">Careers</Link>
        </div>

        {/* Column 2 */}
        <div className="flex flex-col gap-2">
          <h3 className="font-semibold text-white/80">Resources</h3>
          <Link href="/docs" className="text-white/60 hover:text-white">Docs</Link>
          <Link href="/showcase" className="text-white/60 hover:text-white">Showcase</Link>
          <Link href="/faq" className="text-white/60 hover:text-white">FAQ</Link>
        </div>

        {/* Column 3 */}
        <div className="flex flex-col gap-2">
          <h3 className="font-semibold text-white/80">Legal</h3>
          <Link href="/legal/privacy" className="text-white/60 hover:text-white">Privacy Policy</Link>
          <Link href="/legal/terms" className="text-white/60 hover:text-white">Terms of Service</Link>
          <Link href="/legal/cookies" className="text-white/60 hover:text-white">Cookie Policy</Link>
        </div>
      </div>

      {/* Bottom */}
      <div className="mt-12 text-xs text-center text-white/40">
        <p>
          © {new Date().getFullYear()} Fast & Easy Dispatching LLC. All rights reserved.
        </p>
        <p className="mt-1">
          Built with ❤️ by <span className="text-pink-400">OpenHWY</span> & <span className="text-purple-400">MARK</span>.
        </p>
      </div>
    </footer>
  )
}
