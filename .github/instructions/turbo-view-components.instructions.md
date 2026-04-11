# Turbo + ViewComponent + Stimulus in Reelix Manager

Use this pattern when a page should keep its outer shell stable and only refresh the dynamic regions that actually changed.

## Preferred split

Build the page in three layers:

1. **HTML page shell** — regular controller `format.html` response with stable layout, heading, and form mount points.
2. **ViewComponents** — small render units for each dynamic region (`count`, `controls`, `results`, `card`).
3. **Turbo Stream response** — `format.turbo_stream` template that replaces only the DOM targets that changed.

For search/filter pages, prefer:

- a stable search form rendered once in HTML
- a Turbo Stream GET response for results/count updates
- a small Stimulus controller for local UI state (active tab, hidden fields, debounced submit)

Avoid replacing the search input on every keystroke unless the UX explicitly needs it — it can steal focus and feels jumpy.

## Recommended controller shape

```ruby
class ItemsController < ApplicationController
  #: () -> void
  def index
    @query = params[:q].to_s.strip #: String
    @items = load_items #: Array[Item]

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  #: () -> Array[Item]
  def load_items
    Item.search(@query).order(:name).load.to_a
  end
end
```

Rules:

- Prefer arrays in view-facing instance variables when components only need iteration/counting.
- Keep filtering/sorting in one private query method.
- Always provide both `html` and `turbo_stream` responses.

## Recommended view structure

`app/views/items/index.html.erb`

```erb
<div class="d-flex align-items-center justify-content-between mb-3">
  <h1 class="h3 mb-0">Items</h1>
  <div id="items_count">
    <%= render Items::CountComponent.new(count: @items.size) %>
  </div>
</div>

<div id="items_controls" class="mb-4">
  <%= render Items::ControlsComponent.new(query: @query, filter: @filter) %>
</div>

<div id="items_results">
  <%= render Items::ResultsComponent.new(items: @items, query: @query) %>
</div>
```

`app/views/items/index.turbo_stream.erb`

```erb
<%= turbo_stream.replace "items_count" do %>
  <%= render Items::CountComponent.new(count: @items.size) %>
<% end %>

<%= turbo_stream.replace "items_results" do %>
  <%= render Items::ResultsComponent.new(items: @items, query: @query) %>
<% end %>
```

Rules:

- Give every replaceable region a stable DOM id.
- Replace only the regions that changed.
- Keep controls outside the Turbo Stream replacements unless the response must change the control markup too.

## Component layout

Create one component per UI responsibility:

- `CountComponent` — summary text like `12 blobs`
- `ControlsComponent` — form, buttons, hidden fields
- `ResultsComponent` — empty state vs grid/list wrapper
- `CardComponent` — each repeated item

Keep the public initializer as the component interface. Pass plain values (`String`, `Integer`, `Array[Model]`) where possible.

## Stimulus role

Stimulus should manage local UI state, not server rendering:

- update active tab classes
- sync hidden fields
- debounce text input submission
- submit the GET form

Do **not** rebuild server-rendered HTML in JavaScript.

For filter tabs, prefer `button_tag type="button"` inside the GET form over navigation links when the interaction should submit the existing query + filter state together.

## Turbo GET forms

Use `form_with` GET + Turbo Streams:

```erb
<%= form_with url: items_path,
              method: :get,
              data: {
                controller: "submit-on-keyup item-filters",
                turbo_stream: true,
                "submit-on-keyup-target": "form"
              } do |f| %>
```

Rules:

- Set `data-turbo-stream="true"` on GET forms that should receive Turbo Stream responses.
- Use hidden fields for server-owned filter params.
- Keep a normal submit button so the form still works without debounce interactions.

## Testing

Use **component tests** for markup contracts and **controller tests** for Turbo Stream wiring.

Component tests should cover:

- count text / pluralization
- active tab state
- empty state copy
- rendered cards / item metadata

Controller tests should cover:

- HTML page render
- Turbo Stream response content type
- expected Turbo Stream targets being replaced
- filtering/search results

Example:

```ruby
class Items::ResultsComponentTest < ViewComponent::TestCase
  test "renders empty state" do
    render_inline(Items::ResultsComponent.new(items: [], query: "Missing"))

    assert_text "No items found for “Missing”."
  end
end
```

## File checklist

When building a new Turbo + ViewComponent page, update all relevant surfaces:

- `Gemfile` if ViewComponent is not already installed
- controller `respond_to`
- `index.html.erb`
- `index.turbo_stream.erb`
- component Ruby classes + templates under `app/components/`
- Stimulus controller registration in `app/javascript/controllers/index.js`
- assets compile step if you generated a new controller
- component/controller tests

## Commands

After adding a new Stimulus controller:

```bash
bin/rails generate stimulus your_controller
bin/rails assets:precompile
```

After changing Ruby annotations:

```bash
bundle exec rake type_check
```

Before finishing:

```bash
npm run build:css
bin/rails test
```
