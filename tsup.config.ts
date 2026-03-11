import { defineConfig } from 'tsup'

export default defineConfig({
  entry: ['src/main.ts'],
  format: ['cjs'],
  target: 'node20',
  outDir: 'dist',
  clean: true,
  sourcemap: true,
  banner: {
    // Run before any module code; @actual-app/api expects navigator (browser global)
    js: [
      '#!/usr/bin/env node',
      '(function(){if(typeof globalThis.navigator==="undefined"){globalThis.navigator={userAgent:"Node"};}})();',
    ].join('\n'),
  },
})
