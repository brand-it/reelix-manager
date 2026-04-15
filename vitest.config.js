import { defineConfig } from 'vitest/config'
import { dirname, resolve } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['app/javascript/**/*_test.js'],
    setupFiles: ['app/javascript/test/setup.js'],
    alias: {
      '@controllers': resolve(__dirname, 'app/javascript/controllers'),
      '@helpers': resolve(__dirname, 'app/javascript/helpers')
    }
  }
})
