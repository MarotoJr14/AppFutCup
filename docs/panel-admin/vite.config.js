import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ command }) => ({
  // When the app is built under a subpath (e.g. docs/), keep asset URLs relative.
  base: command === 'build' ? './' : '/',
  plugins: [react()],
  server: { port: 3000 }
}))
