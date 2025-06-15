import { defineConfig } from 'tsup'

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs', 'esm'],
  dts: {
    resolve: true,
    entry: 'src/index.ts',
    tsconfig: './tsconfig.json' // ✅ correct — belongs inside `dts`
  },
  clean: true,
  sourcemap: true,
  target: 'es2020',
  outDir: 'dist',
  external: ['react-native-web']
})
