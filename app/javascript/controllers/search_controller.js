import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  connect() {
    this.timeout = null
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.timeout = null
  }

  // Debounce: wait 300ms after the last keystroke before submitting the form.
  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}
