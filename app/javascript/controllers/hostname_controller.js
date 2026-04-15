import { Controller } from "@hotwired/stimulus"

/**
 * Replaces YOUR_HOST placeholders with the current hostname.
 * 
 * Usage:
 *   <pre data-controller="hostname">
 *   <code data-hostname-target="code">curl -X POST https://YOUR_HOST/...</code>
 *   </pre>
 */
export default class extends Controller {
  static targets = ["code"]
  
  connect() {
    const hostname = `${window.location.hostname}${window.location.port ? ':' + window.location.port : ''}`
    const httpsUrl = `https://${hostname}`
    
    console.log('[HostnameController] connected, targets found:', this.codeTargets.length)
    console.log('[HostnameController] hostname to use:', `${httpsUrl}, ${hostname}`)
    
    this.codeTargets.forEach((target) => {
      const original = target.textContent
      
      // Handle two cases:
      // 1. YOUR_HOST preceded by a protocol (http:// or https://) → replace YOUR_HOST with hostname only
      // 2. YOUR_HOST without preceding protocol → replace with full https://URL
      const updated = original.replace(/(https?:\/\/)(YOUR_HOST)|YOUR_HOST/g, (match, protocol, yourHost) => {
        if (protocol) {
          // Protocol is already present, just replace YOUR_HOST
          return protocol + hostname
        }
        // No protocol, use full https URL
        return httpsUrl
      })
      
      console.log('[HostnameController] processing target...')
      console.log('[HostnameController] original (first 100 chars):', original.substring(0, 100))
      console.log('[HostnameController] has YOUR_HOST:', original.includes('YOUR_HOST'))
      console.log('[HostnameController] updated (first 100 chars):', updated.substring(0, 100))
      
      target.textContent = updated
    })
  }

}