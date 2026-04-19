import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="polling"
//
// Automatically polls a page or element at a specified interval using Turbo Drive.
// The page refreshes without a full reload, keeping the browser state intact.
//
// Values:
//   interval: Polling interval in milliseconds (default: 2000)
//   url: Optional custom URL to poll (default: current page)
//
// Usage:
//   <div data-controller="polling"
//        data-polling-interval-value="2000"
//        data-action="turbo:load->polling#start turbo:load->polling#resetInFlight">
//     <div data-polling-target="content">...</div>
//   </div>
//
// Or without a content target (polls entire page):
//   <body data-controller="polling"
//         data-polling-interval-value="2000"
//         data-action="turbo:load->polling#start turbo:load->polling#resetInFlight">
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 2000 },
    url: { type: String, default: "" }
  }

  static targets = ["content"]

  connect() {
    this.timer = null
    this.inFlight = false
  }

  disconnect() {
    this.stop()
  }

  start() {
    this.stop()
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  poll() {
    // Skip polling if there's already a request in-flight
    if (this.inFlight) return

    if (!this.element.isConnected) return

    this.inFlight = true

    const url = this.urlValue || window.location.href
    // Use Turbo Drive to visit the URL without a full page reload
    Turbo.visit(url, {
      action: this.hasContentTarget ? "replace" : "advance",
      frame: this.hasContentTarget ? "main" : undefined
    })
  }

  resetInFlight() {
    this.inFlight = false
  }
}
