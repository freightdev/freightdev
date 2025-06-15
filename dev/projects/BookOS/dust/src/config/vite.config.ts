import react from '@vitejs/plugin-react'
import * as path from 'path'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@ui': path.join(__dirname, '../../packages/ui/src'),
    },
  },
  define: {
    'process.env': {}, // Required by some packages expecting `process.env` (e.g., Storybook/Vite shims)
    'process.platform': JSON.stringify(process.platform),
    'process.version': JSON.stringify(process.version),
  },
})
