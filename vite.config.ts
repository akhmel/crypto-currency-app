import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react({
      jsxImportSource: 'react',
      jsxRuntime: 'automatic'
    })
  ],
  esbuild: {
    jsx: 'automatic'
  }
})
