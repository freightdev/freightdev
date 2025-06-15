export function HeroTabSwitcher() {
  return (
    <div className="mt-12 flex justify-center space-x-4 text-sm sm:text-base font-medium">
      <button className="px-5 py-2 border-b-2 border-white text-white transition-all hover:text-pink-400 hover:border-pink-400">
        CargoConnect
      </button>
      <button className="px-5 py-2 border-b-2 border-pink-500 text-pink-500 font-semibold transition-all">
        FED TMS
      </button>
      <button className="px-5 py-2 border-b-2 border-white text-white transition-all hover:text-pink-400 hover:border-pink-400">
        PacketPilot
      </button>
    </div>
  )
}
