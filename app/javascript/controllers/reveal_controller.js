import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
// Toggles an input field between password (hidden) and text (visible).
// The toggle button carries both label states via data attributes.
//
// Usage:
//   <div data-controller="reveal">
//     <input data-reveal-target="field" type="password" ...>
//     <button data-reveal-target="toggle"
//             data-action="reveal#toggle"
//             data-reveal-show-label="Show"
//             data-reveal-hide-label="Hide">Show</button>
//   </div>
export default class extends Controller {
  static targets = ["field", "toggle"]

  toggle() {
    const isHidden = this.fieldTarget.type === "password"
    this.fieldTarget.type = isHidden ? "text" : "password"
    this.toggleTarget.textContent = isHidden
      ? this.toggleTarget.dataset.revealHideLabel
      : this.toggleTarget.dataset.revealShowLabel
  }
}
