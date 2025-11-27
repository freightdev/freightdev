import { colors, fonts } from '../tokens/tailwind-tokens'

export const tailwindTheme = {
  darkMode: 'class',
  extend: {
    colors: {
      primary: colors.primary,
      secondary: colors.secondary,
      accent: colors.accent,
      background: colors.background,
      foreground: colors.foreground,
    },
    fontFamily: {
      sans: [fonts.sans],
      mono: [fonts.mono],
    },
  },
}
