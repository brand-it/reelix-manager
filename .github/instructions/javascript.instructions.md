# JavaScript in Reelix Manager

This project uses [Stimulus](https://stimulus.hotwired.dev/) for all JavaScript behaviour. Do not write inline `<script>` tags or jQuery-style DOM manipulation — use a Stimulus controller instead.

## How it works

The stack is:

- **Stimulus** — behaviour attached to HTML via `data-` attributes
- **Turbo** — handles page navigation without full reloads
- **Import maps** — no build step; JS is served directly from `app/javascript/`

Controllers are registered explicitly in `controllers/index.js` using static imports. This is more reliable than the `eagerLoadControllersFrom` dynamic approach because it avoids silent async failures.

---

## Creating a controller

**Always use the Rails generator.** It creates the file in the right place and adds the comment header that documents the controller identifier:

```bash
bin/rails generate stimulus my_feature
# creates: app/javascript/controllers/my_feature_controller.js
# identifier: my-feature  (underscores → hyphens)
```

**After generating a controller, do two things:**

1. Add a static import to `app/javascript/controllers/index.js`:

```js
import MyFeatureController from "controllers/my_feature_controller"
application.register("my-feature", MyFeatureController)
```

2. Recompile assets so the importmap picks up the new file:

```bash
bin/rails assets:precompile
```

> This project uses precompiled static assets in `public/assets/`. The importmap resolver only knows about compiled files — new controllers are invisible to the browser until compiled.

The filename determines the controller identifier: `my_feature_controller.js` → `data-controller="my-feature"`.

```js
// app/javascript/controllers/my_feature_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="my-feature"
export default class extends Controller {
  // Declare targets (elements this controller manages)
  static targets = ["input", "output"]

  // Declare values (typed data passed from HTML)
  static values = { url: String, count: { type: Number, default: 0 } }

  // Lifecycle — called when the controller connects to the DOM
  connect() {
    console.log("my-feature connected", this.element)
  }

  // Actions are called from data-action attributes in HTML
  doSomething(event) {
    this.outputTarget.textContent = this.inputTarget.value
  }
}
```

---

## Wiring up HTML

```erb
<div data-controller="my-feature">
  <input data-my-feature-target="input" type="text" />
  <span data-my-feature-target="output"></span>
  <button data-action="my-feature#doSomething">Go</button>
</div>
```

### Key data attributes

| Attribute | Purpose |
|-----------|---------|
| `data-controller="name"` | Mounts the controller on this element |
| `data-name-target="targetName"` | Marks an element as a target |
| `data-action="name#method"` | Calls `method` on the controller on click (default event) |
| `data-action="input->name#method"` | Calls `method` on the `input` event instead |
| `data-name-some-value="..."` | Passes a typed value into the controller |

---

## Targets

Targets let a controller reference specific child elements without using `getElementById` or CSS selectors.

```js
static targets = ["button", "panel"]

toggle() {
  this.panelTarget   // first matching element
  this.panelTargets  // all matching elements
  this.hasPanelTarget // true/false
}
```

```html
<div data-my-feature-target="panel">...</div>
```

---

## Values

Values are typed properties passed from HTML attributes into the controller. They trigger a callback when changed — use this pattern for state-driven UI rather than reading the DOM.

```js
static values = { open: { type: Boolean, default: false } }

openValueChanged(value) {
  this.element.classList.toggle("hidden", !value)
}
```

```html
<div data-controller="my-feature" data-my-feature-open-value="true">
```

---

## Ensuring a controller loads (page_scripts pattern)

In development with precompiled assets, there can be cases where a newly added controller isn't picked up by the running server without a restart. To guarantee a controller registers on a specific page, use `content_for :page_scripts` to add an inline ES module import at the bottom of `<body>`. The layout already yields this block.

```erb
<%# In your view or partial: %>
<% content_for :page_scripts do %>
  <script type="module">
    import { application } from "controllers/application"
    import MyFeatureController from "controllers/my_feature_controller"
    application.register("my-feature", MyFeatureController)
  </script>
<% end %>
```

This is a proper ES module (not an inline script hack) — it uses the importmap to resolve modules and registers the controller on the same Stimulus application instance. If the controller is already registered by `index.js`, Stimulus handles the duplicate gracefully.

Use this pattern when:
- A new controller was just generated and `assets:precompile` hasn't been run yet
- A specific page needs a controller that isn't globally registered

---

## Real example — reveal / show-hide field

**Generated with:**
```bash
bin/rails generate stimulus reveal
```

**Controller:** `app/javascript/controllers/reveal_controller.js`

This is a reusable controller that works on any input field. It starts the field as `type="password"` (masked) on connect, and toggles via separate Show/Hide buttons.

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
export default class extends Controller {
  static targets = ["field", "showButton", "hideButton"]

  connect() {
    this.fieldTarget.type = "password"
    if (this.hasShowButtonTarget) this.showButtonTarget.hidden = false
    if (this.hasHideButtonTarget) this.hideButtonTarget.hidden = true
  }

  show() {
    this.fieldTarget.type = "text"
    if (this.hasShowButtonTarget) this.showButtonTarget.hidden = true
    if (this.hasHideButtonTarget) this.hideButtonTarget.hidden = false
  }

  hide() {
    this.fieldTarget.type = "password"
    if (this.hasShowButtonTarget) this.showButtonTarget.hidden = false
    if (this.hasHideButtonTarget) this.hideButtonTarget.hidden = true
  }
}
```

**HTML (using simple_form `f.input_field` for Bootstrap input-groups):**

```erb
<%# Guarantee the controller loads on this page %>
<% content_for :page_scripts do %>
  <script type="module">
    import { application } from "controllers/application"
    import RevealController from "controllers/reveal_controller"
    application.register("reveal", RevealController)
  </script>
<% end %>

<div class="mb-3" data-controller="reveal">
  <%= f.label :api_key, "API Key", class: "form-label" %>
  <div class="input-group">
    <%= f.input_field :api_key,
          as: :password,
          data: { reveal_target: "field" },
          class: "form-control",
          autocomplete: "off" %>
    <button type="button"
            data-reveal-target="showButton"
            data-action="reveal#show"
            class="btn btn-outline-secondary">Show</button>
    <button type="button"
            data-reveal-target="hideButton"
            data-action="reveal#hide"
            class="btn btn-outline-secondary"
            hidden>Hide</button>
  </div>
  <%= f.full_error :api_key, class: "invalid-feedback d-block" %>
  <%= f.hint "Your API key" %>
</div>
```

Key points:
- `f.input_field as: :password` renders `type="password"` from the server — the field is masked before any JS runs
- `data: { reveal_target: "field" }` (underscore) → renders as `data-reveal-target="field"` — the Rails-idiomatic way
- Two separate buttons (`showButton` / `hideButton`) — no JS text manipulation needed
- Works with any input field, not just passwords

---

## Rules

- **Always use the generator.** `bin/rails generate stimulus name` — never create `*_controller.js` files by hand.
- **Always add to index.js.** After generating, add `import` + `application.register()` to `controllers/index.js`.
- **Always recompile after generating.** Run `bin/rails assets:precompile` after adding a new controller.
- **Use `content_for :page_scripts` for per-page controller loading.** When you need a controller on one page, use the inline ES module pattern rather than global registration.
- **Never use private class field syntax (`#method`).** It can silently prevent module loading in some environments.
- **Never use `getElementById` or `querySelector` from a controller.** Use targets — they scope lookups to the controller element and are Turbo-safe.
- **One controller per behaviour.** Small, focused controllers are easier to reuse.
- **Use `connect()` for initial DOM state.** Set up initial DOM state in `connect()` rather than value callbacks for simpler, more predictable behaviour.
- **Controllers are Turbo-safe.** `connect()` / `disconnect()` fire correctly on Turbo navigation; inline scripts do not.


---

## Creating a controller

**Always use the Rails generator.** It creates the file in the right place and adds the comment header that documents the controller identifier:

```bash
bin/rails generate stimulus my_feature
# creates: app/javascript/controllers/my_feature_controller.js
# identifier: my-feature  (underscores → hyphens)
```

**After generating a controller, recompile assets** so the importmap picks it up:

```bash
bin/rails assets:precompile
```

> This project uses precompiled static assets in `public/assets/`. The importmap resolver only knows about compiled files — new controllers are invisible to the browser until compiled.

The filename determines the controller identifier: `my_feature_controller.js` → `data-controller="my-feature"`.

```js
// app/javascript/controllers/my_feature_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="my-feature"
export default class extends Controller {
  // Declare targets (elements this controller manages)
  static targets = ["input", "output"]

  // Declare values (typed data passed from HTML)
  static values = { url: String, count: { type: Number, default: 0 } }

  // Lifecycle — called when the controller connects to the DOM
  connect() {
    console.log("my-feature connected", this.element)
  }

  // Actions are called from data-action attributes in HTML
  doSomething(event) {
    this.outputTarget.textContent = this.inputTarget.value
  }
}
```

---

## Wiring up HTML

```erb
<div data-controller="my-feature">
  <input data-my-feature-target="input" type="text" />
  <span data-my-feature-target="output"></span>
  <button data-action="my-feature#doSomething">Go</button>
</div>
```

### Key data attributes

| Attribute | Purpose |
|-----------|---------|
| `data-controller="name"` | Mounts the controller on this element |
| `data-name-target="targetName"` | Marks an element as a target |
| `data-action="name#method"` | Calls `method` on the controller on click (default event) |
| `data-action="input->name#method"` | Calls `method` on the `input` event instead |
| `data-name-some-value="..."` | Passes a typed value into the controller |

---

## Targets

Targets let a controller reference specific child elements without using `getElementById` or CSS selectors.

```js
static targets = ["button", "panel"]

toggle() {
  this.panelTarget   // first matching element
  this.panelTargets  // all matching elements
  this.hasPanelTarget // true/false
}
```

```html
<div data-my-feature-target="panel">...</div>
```

---

## Values

Values are typed properties passed from HTML attributes into the controller. They trigger a callback when changed — use this pattern for state-driven UI rather than reading the DOM.

```js
static values = { open: { type: Boolean, default: false } }

openValueChanged(value) {
  this.element.classList.toggle("hidden", !value)
}
```

```html
<div data-controller="my-feature" data-my-feature-open-value="true">
```

---

## Real example — reveal / show-hide field

**Generated with:**
```bash
bin/rails generate stimulus reveal
```

**Controller:** `app/javascript/controllers/reveal_controller.js`

This is a reusable controller that works on any input field. It starts the field hidden (`type="password"`) and shows separate Show/Hide buttons to toggle visibility.

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
export default class extends Controller {
  static targets = ["field", "showButton", "hideButton"]
  static values  = { hidden: { type: Boolean, default: true } }

  // hiddenValueChanged fires automatically on connect (initial value) and on every change.
  hiddenValueChanged(value) {
    this.fieldTarget.type = value ? "password" : "text"
    if (this.hasShowButtonTarget) this.showButtonTarget.hidden = !value
    if (this.hasHideButtonTarget) this.hideButtonTarget.hidden = value
  }

  show() { this.hiddenValue = false }
  hide() { this.hiddenValue = true }
}
```

**HTML (in ERB):**

```erb
<div data-controller="reveal">
  <%= f.text_field :api_key,
        data: { "reveal-target": "field" },
        class: "form-control",
        autocomplete: "off" %>
  <button type="button"
          data-reveal-target="showButton"
          data-action="reveal#show"
          class="btn btn-outline-secondary">Show</button>
  <button type="button"
          data-reveal-target="hideButton"
          data-action="reveal#hide"
          class="btn btn-outline-secondary"
          hidden>Hide</button>
</div>
```

Key points:
- Two separate buttons (`showButton` / `hideButton`) — no JS text manipulation needed
- The controller drives both the field `type` and button visibility from a single `hiddenValue`
- Works with any input field, not just passwords

---

## Rules

- **Always use the generator.** `bin/rails generate stimulus name` — never create `*_controller.js` files by hand.
- **Always recompile after generating.** Run `bin/rails assets:precompile` after adding a new controller — the importmap only resolves compiled files.
- **Never write inline `<script>` tags.** Move the logic into a controller.
- **Never use `getElementById` or `querySelector` from a controller.** Use targets instead — they scope lookups to the controller element and are Turbo-safe.
- **One controller per behaviour.** Small, focused controllers are easier to reuse.
- **Use values for state, not DOM inspection.** `hiddenValueChanged` is called automatically — don't read `element.type` to determine state.
- **Controllers are Turbo-safe.** `connect()` / `disconnect()` fire correctly on Turbo navigation, inline scripts do not.
