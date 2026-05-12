import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="submit-on-keyup"
//
// Generic form-submission helper. Attach to any wrapper element that contains a
// form target and one or more input targets. The form is submitted
// automatically 300 ms after the last input/change event, but only when the
// value has actually changed since the previous submission.
//
// Usage:
//   <div data-controller="submit-on-keyup">
//     <form data-submit-on-keyup-target="form">
//       <input type="text"
//              name="q"
//              data-submit-on-keyup-target="input"
//              data-action="input->submit-on-keyup#submit">
//       <input type="radio"
//              name="media_type"
//              value="movie"
//              data-submit-on-keyup-target="input"
//              data-action="change->submit-on-keyup#submit">
//     </form>
//   </div>
export default class extends Controller {
  static targets = ["input", "form"];

  connect() {
    this.lastSubmittedValues = new Map();
    this.timeout = null;

    this.inputTargets.forEach((input) => {
      this.lastSubmittedValues.set(input.name || input.id, input.value);
    });
  }

  disconnect() {
    clearTimeout(this.timeout);
    this.timeout = null;
  }

  submit(event) {
    const input = event.currentTarget;
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.timeout = null;
      if (!this.element.isConnected) return;

      this.requestSubmitIfChanged(input);
    }, 300);
  }

  // Compatibility for stale cached markup that still uses
  // change->submit-on-keyup#submitNow.
  submitNow(event) {
    clearTimeout(this.timeout);
    this.timeout = null;
    this.requestSubmitIfChanged(event.currentTarget);
  }

  // Compatibility for stale cached markup that still uses
  // click->submit-on-keyup#submitFilter on a <label>.
  submitFilter(event) {
    const input = event.currentTarget.control;
    if (!input) return;

    clearTimeout(this.timeout);
    this.timeout = null;
    input.checked = true;
    this.requestSubmitIfChanged(input);
  }

  requestSubmitIfChanged(input) {
    if (!this.element.isConnected) return;

    const key = input.name || input.id;
    if (this.lastSubmittedValues.get(key) === input.value) return;

    this.lastSubmittedValues.set(key, input.value);
    this.formTarget.requestSubmit();
  }
}
