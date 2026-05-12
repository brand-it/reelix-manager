import { Controller } from "@hotwired/stimulus";

// Global polling state - only stores the timer and interval
// No controller tracking - we just care if a timer exists
const POLLING = {
  timer: null,
  interval: 2000, // Default interval, updated when new poll starts
};

// Connects to data-controller="polling"
//
// Automatically polls a page at a specified interval using Turbo Drive.
// The page refreshes without a full reload, keeping the browser state intact.
// Only one poller can run globally across all controllers.
//
// Values:
//   interval: Polling interval in milliseconds (default: 2000)
//   url: Optional custom URL to poll (default: current page)
//
// Usage:
//   <div data-controller="polling"
//        data-polling-interval-value="2000">
//     <span data-polling-target="countdown">2</span>s until refresh
//     <div data-polling-target="content">...</div>
//   </div>
//
// Or with a spinner:
//   <div data-controller="polling"
//        data-polling-interval-value="2000">
//     <div data-polling-target="spinner" class="spinner-border spinner-border-sm" role="status">
//       <span class="visually-hidden">Loading...</span>
//     </div>
//     <span data-polling-target="countdown">2</span>s
//     <div data-polling-target="content">...</div>
//   </div>
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 2000 },
    url: { type: String, default: "" },
  };

  static targets = ["countdown", "spinner"];

  // Check if polling is currently active globally
  static get isPolling() {
    return POLLING.timer !== null;
  }

  connect() {
    // Only start polling if we're on the uploads page
    // This prevents the timer from running on other pages
    if (window.location.pathname !== "/uploads") {
      console.log("Polling not started: not on uploads page");
      return;
    }
    console.log("Start Polling");
    this.start();
  }

  disconnect() {
    console.log("Stop Polling");
    this.stop();
  }

  // Start polling - only one timer can exist globally
  start() {
    // If a timer already exists globally, don't start another
    if (POLLING.timer) return;

    // Set up global timer
    POLLING.interval = this.intervalValue;
    POLLING.timer = setInterval(() => this.poll(), this.intervalValue);
    this.lastPollTime = Date.now();
    this.startCountdownLoop();
    this.updateSpinner();
  }

  // Stop polling - clears global timer
  stop() {
    if (POLLING.timer) {
      clearInterval(POLLING.timer);
      POLLING.timer = null;
    }

    this.stopCountdownLoop();
    this.updateSpinner();
  }

  // Restart polling timer after successful poll
  restart() {
    // Clear existing timer
    if (POLLING.timer) {
      clearInterval(POLLING.timer);
    }

    // Start fresh timer
    POLLING.timer = setInterval(() => this.poll(), POLLING.interval);
    this.lastPollTime = Date.now();
  }

  startCountdownLoop() {
    this.updateCountdown();
    this.countdownFrame = requestAnimationFrame(() => {
      this.countdownLoop();
    });
  }

  stopCountdownLoop() {
    if (this.countdownFrame) {
      cancelAnimationFrame(this.countdownFrame);
      this.countdownFrame = null;
    }
  }

  countdownLoop() {
    this.updateCountdown();
    // Continue loop while polling is active
    if (POLLING.timer) {
      this.countdownFrame = requestAnimationFrame(() => {
        this.countdownLoop();
      });
    }
  }

  poll() {
    // Critical: Prevent concurrent requests
    if (this.inFlight || !this.element.isConnected) return;

    this.inFlight = true;
    const url = this.urlValue || window.location.href;

    // Fetch with Turbo Stream accept header for partial updates
    // Note: Must not include */* or Rails will treat it as browser-like
    // and ignore the Accept header, defaulting to HTML
    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html, text/html",
      },
    })
      .then((response) => response.text())
      .then((turboStreamHTML) => {
        Turbo.renderStreamMessage(turboStreamHTML);
      })
      .finally(() => {
        this.inFlight = false;
        this.restart();
      });
  }

  get remainingSeconds() {
    if (!this.lastPollTime) return 0;
    const elapsed = Date.now() - this.lastPollTime;
    const remaining = Math.ceil((POLLING.interval - elapsed) / 1000);
    return Math.max(0, remaining);
  }

  updateCountdown() {
    if (!this.hasCountdownTarget) return;
    this.countdownTarget.textContent = this.remainingSeconds;
  }

  updateSpinner() {
    if (!this.hasSpinnerTarget) return;
    this.spinnerTarget.style.display = POLLING.timer ? "inline-block" : "none";
  }

  // Reset global polling state (used for testing)
  static resetGlobalState() {
    if (POLLING.timer) {
      clearInterval(POLLING.timer);
      POLLING.timer = null;
    }
    POLLING.interval = 2000;
  }
}
