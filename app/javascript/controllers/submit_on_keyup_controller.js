import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-on-keyup"
//
// Generic form-submission debouncer. Attach to any wrapper element that
// contains a form target and one or more input targets. The form is submitted
// automatically 300 ms after the last keystroke, but only when the value has
// actually changed since the previous submission.
//
// Usage:
//   <div data-controller="submit-on-keyup">
//     <form data-submit-on-keyup-target="form">
//       <input type="text" name="q" data-submit-on-keyup-target="input">
//       <input type="text" name="filter" data-submit-on-keyup-target="input">
//     </form>
//   </div>
export default class extends Controller {
  static targets = ["input", "form"]

  connect() {
    this.lastSubmittedValues = new Map()
    this.timeout = null

    this.inputTargets.forEach((input) => {
      this.lastSubmittedValues.set(input.name || input.id, input.value)
    })
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.timeout = null
  }

  // Bound to data-action="input->submit-on-keyup#submit" on each input.
  submit(event) {
    const input = event.currentTarget
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.timeout = null
      if (!this.element.isConnected) return

      const key = input.name || input.id
      if (this.lastSubmittedValues.get(key) === input.value) return

      this.lastSubmittedValues.set(key, input.value)
      this.formTarget.requestSubmit()
    }, 300)
  }
}
