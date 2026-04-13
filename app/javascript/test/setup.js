import { afterEach, expect } from 'vitest'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

// Clean up after each test
afterEach(() => {
  document.body.innerHTML = ''
  window.dispatchEvent(new Event('popstate'))
})
