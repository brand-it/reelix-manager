---
id: hostname-controller
description: Replaces YOUR_HOST placeholders in code snippets with the current hostname. Use when displaying curl commands, API examples, or any code that needs localhost/hostname substitution.
---

The `HostnameController` Stimulus controller replaces `YOUR_HOST` placeholders in `<code>` elements with the current page's hostname. This is useful for displaying curl commands, API documentation, or any code examples that need to work against the current deployment URL.

## Usage

Add the controller and target to your HTML:

```erb
<pre data-controller="hostname">
  <code data-hostname-target="code">
    curl -X POST https://YOUR_HOST/api/endpoint
  </code>
</pre>
```

Or for multiple code blocks:

```erb
<div data-controller="hostname">
  <code data-hostname-target="code">curl YOUR_HOST/api</code>
  <code data-hostname-target="code">wget YOUR_HOST/file</code>
</div>
```

## Behavior

The controller intelligently handles two cases:

1. **YOUR_HOST with protocol** (`https://YOUR_HOST` or `http://YOUR_HOST`) → Replaces only `YOUR_HOST` with the hostname, preserving the protocol
   - `https://YOUR_HOST/api` → `https://example.com/api`
   - `http://YOUR_HOST/users` → `http://localhost:3000/users`

2. **Bare YOUR_HOST** (without protocol) → Replaces with full `https://hostname`
   - `curl YOUR_HOST/api` → `curl https://example.com/api`

The controller reads `window.location.hostname` and includes the port if non-zero.

## Controller Implementation

Create `app/javascript/controllers/hostname_controller.js`:

```javascript
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
      
      target.textContent = updated
    })
  }
}
```

## Testing

See `app/javascript/controllers/hostname_controller_test.js` for test coverage including:

- Single and multiple YOUR_HOST replacements
- Protocol handling (http vs https)
- Edge cases (blocks without YOUR_HOST)
- Multiple code targets

## Notes

- Controller runs on `connect()` lifecycle, replacement happens once when element enters DOM
- Uses Stimulus targets for type-safe element selection
- Default protocol for bare YOUR_HOST is `https`
