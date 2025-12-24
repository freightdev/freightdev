/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        purple: {
          primary: '#d946ef',
          secondary: '#a855f7',
          dark: '#7e22ce',
        },
        background: {
          DEFAULT: '#0a0a0a',
          card: '#1a1a1a',
          elevated: '#2a2a2a',
        },
        text: {
          primary: '#ffffff',
          secondary: '#a1a1aa',
          tertiary: '#71717a',
        },
        success: '#10b981',
        warning: '#f59e0b',
        error: '#ef4444',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        'gradient-purple': 'linear-gradient(135deg, #d946ef 0%, #a855f7 100%)',
      },
    },
  },
  plugins: [],
}
