import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The API is served by `wrangler dev` (Cloudflare Workers runtime, local D1 + R2).
// In development Vite proxies /api so the mini app runs on a single origin.
const API_TARGET = 'http://127.0.0.1:8787';

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
    proxy: {
      '/api': { target: API_TARGET, changeOrigin: true },
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
  },
});
