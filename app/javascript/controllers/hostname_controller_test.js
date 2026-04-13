import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { screen, within } from '@testing-library/dom'
import HostnameController from './hostname_controller'
import { createStimulusTestHelper, simulateLocation } from '../test'

describe('HostnameController', () => {
  const helper = createStimulusTestHelper(HostnameController, 'hostname')

  beforeEach(async () => {
    await helper.start()
  })

  afterEach(() => {
    helper.stop()
  })

  it('replaces YOUR_HOST with the current hostname', async () => {
    simulateLocation('https://example.com')
    
    document.body.innerHTML = `
      <pre data-controller="hostname">
        <code data-hostname-target="code">curl https://YOUR_HOST/api</code>
      </pre>
    `

    // Trigger Stimulus to connect
    await new Promise(resolve => setTimeout(resolve, 100))

    const codeElement = document.querySelector('code')
    expect(codeElement.textContent).toBe('curl https://example.com/api')
  })

  it('replaces YOUR_HOST with http hostname', async () => {
    simulateLocation('http://localhost:3000')
    
    document.body.innerHTML = `
      <pre data-controller="hostname">
        <code data-hostname-target="code">GET http://YOUR_HOST/users</code>
      </pre>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const codeElement = document.querySelector('code')
    expect(codeElement.textContent).toBe('GET http://localhost:3000/users')
  })

  it('replaces multiple YOUR_HOST occurrences', async () => {
    simulateLocation('https://api.example.com')
    
    document.body.innerHTML = `
      <pre data-controller="hostname">
        <code data-hostname-target="code">
          curl -X POST https://YOUR_HOST/token \
          -H "Content-Type: application/json" \
          -d "host=YOUR_HOST"
        </code>
      </pre>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const codeElement = document.querySelector('code')
    expect(codeElement.textContent).toContain('https://api.example.com/token')
    expect(codeElement.textContent).toContain('host=https://api.example.com')
    expect(codeElement.textContent).not.toContain('YOUR_HOST')
  })

  it('handles code blocks without YOUR_HOST', async () => {
    simulateLocation('https://example.com')
    
    document.body.innerHTML = `
      <pre data-controller="hostname">
        <code data-hostname-target="code">
          // This is a comment
          const x = 42
        </code>
      </pre>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const codeElement = document.querySelector('code')
    expect(codeElement.textContent).toContain('const x = 42')
    expect(codeElement.textContent).toContain('// This is a comment')
  })

  it('processes multiple code targets with data-hostname-target', async () => {
    simulateLocation('https://test.example.com')
    
    document.body.innerHTML = `
      <div data-controller="hostname">
        <code data-hostname-target="code">curl YOUR_HOST/api</code>
        <code data-hostname-target="code">wget YOUR_HOST/file</code>
      </div>
    `

    await new Promise(resolve => setTimeout(resolve, 100))

    const codeElements = document.querySelectorAll('code')
    expect(codeElements[0].textContent).toBe('curl https://test.example.com/api')
    expect(codeElements[1].textContent).toBe('wget https://test.example.com/file')
  })
})
