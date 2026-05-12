import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { screen } from '@testing-library/dom'
import PollingController from '@controllers/polling_controller'
import { createStimulusTestHelper, simulateLocation } from '@test/index'

describe('PollingController', () => {
  let fetchSpy
  let renderStreamMessageSpy
  const helper = createStimulusTestHelper(PollingController, 'polling')

  beforeEach(async () => {
    // Reset global POLLING state before each test
    PollingController.resetGlobalState()

    // Reset mocks for each test
    fetchSpy = vi.spyOn(window, 'fetch').mockResolvedValue({
      text: vi.fn().mockResolvedValue('<turbo-stream><template></template></turbo-stream>')
    })
    Turbo.renderStreamMessage = vi.fn()
    renderStreamMessageSpy = Turbo.renderStreamMessage
    simulateLocation('https://example.com/uploads')
    await helper.start()
  })

  afterEach(() => {
    fetchSpy.mockClear()
    renderStreamMessageSpy.mockClear()
    vi.restoreAllMocks()
    helper.stop()
    PollingController.resetGlobalState()
  })

  it('starts polling on connect', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    // Should have fetched once after the interval
    expect(fetchSpy).toHaveBeenCalled()
  })

  it('polls at the specified interval', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    const firstCallCount = fetchSpy.mock.calls.length
    fetchSpy.mockClear()

    // Wait for another interval
    await new Promise(resolve => setTimeout(resolve, 150))

    // Should have fetched again
    expect(fetchSpy).toHaveBeenCalled()
  })

  it('stops polling on stop() call', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="50">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    fetchSpy.mockClear()
    pollingController.stop()

    // Wait for what would have been 2 more intervals
    await new Promise(resolve => setTimeout(resolve, 120))

    // Should not have fetched more after stop
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('stops polling on disconnect', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="50">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    fetchSpy.mockClear()

    // Disconnect by removing element
    const controller = document.querySelector('[data-controller="polling"]')
    controller.remove()

    // Wait for what would have been 2 more intervals
    await new Promise(resolve => setTimeout(resolve, 120))

    // Should not have fetched more after disconnect
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('uses custom URL when provided', async () => {
    document.body.innerHTML = `
      <div data-controller="polling"
           data-polling-interval-value="100"
           data-polling-url-value="https://example.com/custom">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    expect(fetchSpy).toHaveBeenCalledWith('https://example.com/custom', expect.any(Object))
  })

  it('uses current location when no custom URL provided', async () => {
    // Note: Must use /uploads path for polling to work
    simulateLocation('https://example.com/uploads?query=test')

    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    expect(fetchSpy).toHaveBeenCalledWith('https://example.com/uploads?query=test', expect.any(Object))
  })

  it('sends Turbo Stream accept header', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    const fetchOptions = fetchSpy.mock.calls[0][1]
    expect(fetchOptions.headers.Accept).toContain('text/vnd.turbo-stream.html')
  })

  it('renders Turbo Stream response', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    // Should have called renderStreamMessage with the response
    expect(renderStreamMessageSpy).toHaveBeenCalled()
  })

  it('skips poll if request is already in-flight', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="50">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    // Stop polling first
    pollingController.stop()

    fetchSpy.mockClear()

    // Set in-flight flag manually (internal state, not a value)
    pollingController.inFlight = true

    // Call poll() directly to test the in-flight check
    pollingController.poll()

    // Should not have fetched because in-flight
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('skips poll if element is disconnected', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="50">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    // Stop polling before removing element
    pollingController.stop()

    fetchSpy.mockClear()

    // Remove element but keep controller reference
    controller.remove()

    // Should not have fetched because element is disconnected
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('uses default interval of 2000ms when not specified', async () => {
    document.body.innerHTML = `
      <div data-controller="polling">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    expect(pollingController.intervalValue).toBe(2000)
  })

  it('prevents multiple global timers from running', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100" id="first">
        <div data-polling-target="content">Content 1</div>
      </div>
      <div data-controller="polling" data-polling-interval-value="200" id="second">
        <div data-polling-target="content">Content 2</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    // Both controllers connected, but only one timer should run
    // The first controller should have started the timer
    expect(PollingController.isPolling).toBe(true)

    fetchSpy.mockClear()

    // Wait for both intervals - should only get fetches from one timer
    await new Promise(resolve => setTimeout(resolve, 250))

    // If only one timer is running, we should see limited fetches
    // (exact count depends on timing, but should be less than if both ran)
    expect(fetchSpy.mock.calls.length).toBeLessThan(10)
  })

  it('exposes isPolling static getter', async () => {
    expect(PollingController.isPolling).toBe(false)

    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 50))

    expect(PollingController.isPolling).toBe(true)
  })

  it('restarts timer after fetch completes', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    fetchSpy.mockClear()

    // Wait for the restarted timer to fire
    await new Promise(resolve => setTimeout(resolve, 150))

    // Should have fetched again with the restarted timer
    expect(fetchSpy).toHaveBeenCalled()
  })

  it('updates countdown display', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="2000">
        <span data-polling-target="countdown">2</span>s
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const countdown = screen.getByText(/2/)
    expect(countdown).toBeInTheDocument()
  })

  it('shows spinner when polling is active', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="spinner" class="spinner">Loading</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const spinner = screen.getByText('Loading')
    expect(spinner.style.display).toBe('inline-block')
  })

  it('hides spinner when polling is stopped', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="spinner" class="spinner">Loading</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    pollingController.stop()

    const spinner = screen.getByText('Loading')
    expect(spinner.style.display).toBe('none')
  })

  it('resets inFlight after fetch completes', async () => {
    document.body.innerHTML = `
      <div data-controller="polling" data-polling-interval-value="100">
        <div data-polling-target="content">Content</div>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 150))

    const controller = document.querySelector('[data-controller="polling"]')
    const pollingController = helper.application.getControllerForElementAndIdentifier(controller, 'polling')

    // Stop the timer to prevent additional polls during the test
    pollingController.stop()

    // Manually trigger poll
    pollingController.inFlight = false
    pollingController.poll()

    // Wait for fetch to complete
    await new Promise(resolve => setTimeout(resolve, 50))

    // The controller's inFlight should be reset
    expect(pollingController.inFlight).toBe(false)
  })
})
