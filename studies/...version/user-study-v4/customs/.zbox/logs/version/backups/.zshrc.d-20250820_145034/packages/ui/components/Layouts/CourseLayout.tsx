'use client'

import { ReactNode } from 'react'

export function CourseLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-gradient-to-b from-[#120026] via-[#1f002f] to-[#2a0040] text-white px-6 py-10">
      {/* Course sidebar or step nav goes here */}
      {children}
    </div>
  )
}
