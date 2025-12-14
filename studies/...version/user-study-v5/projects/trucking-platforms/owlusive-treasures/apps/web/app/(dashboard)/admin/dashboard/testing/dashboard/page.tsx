'use client'

export default function BouncePage() {
  return (
    <main className="flex items-end justify-center min-h-screen overflow-hidden bg-black">
      <div className="relative h-[80vh] w-full max-w-screen-sm">
        <div className="absolute bottom-0 -translate-x-1/2 left-1/2 animate-bounceBall">
          <div className="w-16 h-16 bg-blue-500 rounded-full shadow-lg" />
        </div>
      </div>
    </main>
  )
}
