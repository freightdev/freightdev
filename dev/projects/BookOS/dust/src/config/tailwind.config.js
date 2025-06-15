module.exports = {
content: [
  '../../apps/web/app/**/*.{ts,tsx}',
  '../../apps/web/components/**/*.{ts,tsx}',
  './src/**/*.{ts,tsx}'
],

  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        // define other required theme tokens
      },
    },
  },
  plugins: [],
}
