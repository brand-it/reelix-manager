import { afterEach, expect, vi } from 'vitest'
import * as matchers from '@testing-library/jest-dom/matchers'


expect.extend(matchers)

// Mock Turbo for testing
global.Turbo = {
  visit: vi.fn(),
  drive: {
    visit: vi.fn(),
  },
}

// Clean up after each test
afterEach(() => {
  document.body.innerHTML = ''
  window.dispatchEvent(new Event('popstate'))
})
