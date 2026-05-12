import { Application } from '@hotwired/stimulus'

/**
 * Creates a Stimulus test helper for a specific controller
 * @param {Function} controller - The controller class to test
 * @param {string} controllerName - The controller name (e.g., 'hostname')
 * @returns {Object} - Test utilities
 */
export function createStimulusTestHelper(controller, controllerName) {
  let application = null

  // Start a fresh Stimulus application
  function start() {
    // Reset document
    document.body.innerHTML = ''
    
    // Create new application instance
    application = Application.start()
    application.debug = false
    application.register(controllerName, controller)
    
    // Wait for Stimulus to connect controllers
    return new Promise(resolve => setTimeout(resolve, 100))
  }

  // Stop the application
  function stop() {
    if (application) {
      application.stop()
      application = null
    }
  }

  return {
    start,
    stop,
    get application() {
      return application
    }
  }
}
/**
 * Simulates window.location for testing
 * @param {string} url - The URL to simulate
 */
export function simulateLocation(url) {
  const parsed = new URL(url, 'http://localhost')
  Object.defineProperty(window, 'location', {
    value: {
      hostname: parsed.hostname,
      port: parsed.port,
      protocol: parsed.protocol,
      href: parsed.href,
      origin: parsed.origin,
      pathname: parsed.pathname
    },
    writable: true,
    configurable: true
  })
}
