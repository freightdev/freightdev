'use client'

export function Sidebar() {
  return (
    <aside className="w-64 h-full p-4 space-y-4 text-white bg-zinc-900">
      <div className="text-xl font-bold tracking-tight">Dashboard</div>
      <nav className="space-y-2">
        <a href="#" className="block px-3 py-2 rounded-md hover:bg-zinc-800">
          Overview
        </a>
        <a href="#" className="block px-3 py-2 rounded-md hover:bg-zinc-800">
          Loads
        </a>
        <a href="#" className="block px-3 py-2 rounded-md hover:bg-zinc-800">
          Tools
        </a>
        <a href="#" className="block px-3 py-2 rounded-md hover:bg-zinc-800">
          Settings
        </a>
      </nav>
    </aside>
  )
}
