# Simple Form in Reelix Manager

This project uses [simple_form](https://github.com/heartcombo/simple_form) 5.x with Bootstrap 5.

**Configuration files:**
- `config/initializers/simple_form.rb` — base config
- `config/initializers/simple_form_bootstrap.rb` — Bootstrap 5 wrapper definitions (`:default`, `:form_check`)

---

## Basic form structure

```erb
<%= simple_form_for @record, url: url, method: @record.persisted? ? :patch : :post do |f| %>
  <%= f.error_notification %>
  <%= f.error_notification message: f.object.errors[:base].to_sentence if f.object.errors[:base].present? %>

  <%= f.input :name %>
  <%= f.input :email %>

  <%= f.button :submit, class: "btn btn-primary" %>
<% end %>
```

`f.error_notification` renders an `<div class="alert alert-danger">` when the object has errors. Always include both lines — the second catches `:base` errors explicitly.

---

## `f.input` — the standard building block

`f.input` renders the full Bootstrap wrapper: label + input + hint + inline errors.

```erb
<%# Label inferred from attribute name %>
<%= f.input :title %>

<%# Custom label and hint %>
<%= f.input :movie_path,
            label: "Movie Directory",
            hint: "Absolute path where movie files are stored" %>

<%# Override the input type %>
<%= f.input :description, as: :text %>
<%= f.input :api_key,     as: :password %>

<%# HTML options on the input element itself %>
<%= f.input :notes, input_html: { rows: 4, class: "special" } %>

<%# HTML options on the wrapper div %>
<%= f.input :name, wrapper_html: { class: "col-md-6", data: { controller: "reveal" } } %>

<%# Disable label, hint, or error %>
<%= f.input :token, label: false %>
<%= f.input :password, hint: false %>

<%# Required / optional %>
<%= f.input :nickname, required: false %>
```

### What the `:default` wrapper renders

```html
<div class="mb-3">
  <label class="form-label" for="record_movie_path">Movie Directory</label>
  <input class="form-control" type="text" name="record[movie_path]" id="record_movie_path" />
  <div class="invalid-feedback">can't be blank</div>   <!-- only when invalid -->
  <div class="form-text text-muted">Absolute path...</div>  <!-- hint -->
</div>
```

The input automatically gets `is-invalid` / `is-valid` when there are validation errors or successes.

---

## Available `as:` types

| `as:` value     | HTML element            | Auto-detected when                        |
|-----------------|-------------------------|-------------------------------------------|
| `string`        | `input[type=text]`      | string column                             |
| `password`      | `input[type=password]`  | attribute name matches `/password/`       |
| `email`         | `input[type=email]`     | attribute name matches `/email/`          |
| `url`           | `input[type=url]`       | attribute name matches `/url/`            |
| `tel`           | `input[type=tel]`       | attribute name matches `/phone/`          |
| `text`          | `textarea`              | text column                               |
| `boolean`       | `input[type=checkbox]`  | boolean column                            |
| `integer`       | `input[type=number]`    | integer column                            |
| `select`        | `select`                | associations                              |
| `radio_buttons` | collection of radios    | belongs_to association                    |
| `check_boxes`   | collection of checkboxes| has_many association                      |
| `hidden`        | `input[type=hidden]`    | —                                         |
| `file`          | `input[type=file]`      | string with file methods                  |
| `date`          | date select             | date column                               |
| `datetime`      | datetime select         | datetime/timestamp column                 |

Force any type with `as:`:

```erb
<%= f.input :api_key, as: :password %>
<%= f.input :notes,   as: :text %>
<%= f.input :role,    as: :radio_buttons, collection: %w[admin editor viewer] %>
```

---

## Individual component helpers

Use these when you need to break out of the full wrapper — e.g. inside a Bootstrap input-group.

```erb
<%= f.label    :api_key, "API Key", class: "form-label" %>
<%= f.input_field :api_key, as: :password %>   <%# input only, no wrapper %>
<%= f.hint     "Your TMDB API key" %>
<%= f.error    :api_key %>
<%= f.full_error :api_key %>
```

`f.input_field` strips all wrapper divs and renders just the `<input>`. It accepts the same options as `f.input`, including `as:`.

### Bootstrap input-group with show/hide (Stimulus `reveal` controller)

Use `f.input_field as: :password` inside an input-group, then handle label/error/hint individually:

```erb
<div class="mb-3" data-controller="reveal">
  <%= f.label :api_key, "API Key", class: "form-label" %>
  <div class="input-group">
    <%= f.input_field :api_key,
                      as: :password,
                      class: "form-control",
                      autocomplete: "off",
                      data: { "reveal-target": "field" } %>
    <button type="button" class="btn btn-outline-secondary"
            data-reveal-target="showButton"
            data-action="reveal#show">Show</button>
    <button type="button" class="btn btn-outline-secondary"
            data-reveal-target="hideButton"
            data-action="reveal#hide"
            hidden>Hide</button>
  </div>
  <%= f.full_error :api_key, class: "invalid-feedback d-block" %>
  <%= f.hint "Your API key from TMDB." %>
</div>
```

Key points:
- `as: :password` renders `type="password"` from the server — the field is masked before any JS runs
- `f.input_field` keeps Bootstrap's `is-invalid` class behaviour without the wrapper div
- `f.full_error` with `d-block` forces the error to show (Bootstrap hides `.invalid-feedback` without a sibling `.is-invalid` input)
- `f.hint` wraps the text in `<div class="form-text text-muted">`

---

## Wrapping custom HTML inside `f.input`

Pass a block to keep the wrapper (label, errors, hint) but control the inner HTML:

```erb
<%= f.input :role, wrapper_html: { data: { controller: "my-controller" } } do %>
  <%= f.select :role, Role.all.map { |r| [r.name, r.id] }, include_blank: "Select..." %>
<% end %>
```

---

## Collections and associations

```erb
<%# Select from a range %>
<%= f.input :age, collection: 18..99 %>

<%# Select from a model %>
<%= f.input :category_id, collection: Category.order(:name), label_method: :name, value_method: :id %>

<%# Radio buttons %>
<%= f.input :status, as: :radio_buttons, collection: %w[pending active archived] %>

<%# Belongs-to association %>
<%= f.association :company %>
<%= f.association :company, as: :radio_buttons, collection: Company.active.order(:name) %>

<%# Has-many association %>
<%= f.association :roles, as: :check_boxes %>
```

---

## Booleans (checkboxes)

```erb
<%# Default: nested label + checkbox %>
<%= f.input :active, as: :boolean, label: "Active?" %>

<%# Inline style (checkbox without nested label) %>
<%= f.input :active, as: :boolean, wrapper: :form_check %>
```

---

## Buttons

```erb
<%# Renders "Create Record" or "Update Record" automatically %>
<%= f.button :submit %>

<%# Custom label %>
<%= f.button :submit, "Save Settings", class: "btn btn-primary" %>

<%# <button> element %>
<%= f.button :button, "Cancel" %>
```

---

## Custom inputs (`app/inputs/`)

Create `app/inputs/my_custom_input.rb` inheriting from `SimpleForm::Inputs::Base`:

```ruby
class RevealInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    merged = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.password_field(attribute_name, merged)
  end
end
```

Use with `f.input :api_key, as: :reveal`.

---

## I18n — labels, hints, placeholders from locale files

Instead of passing `label:` and `hint:` inline on every field, define them in `config/locales/`:

```yaml
# config/locales/simple_form.en.yml
en:
  simple_form:
    labels:
      config_video:
        settings_tmdb_api_key: "TMDB API Key"
    hints:
      config_video:
        settings_tmdb_api_key: "Your API key from themoviedb.org"
    placeholders:
      defaults:
        settings_movie_path: "/media/movies"
```

Then your views just use `f.input :settings_tmdb_api_key` with no extra options — simple_form looks up the locale automatically.

---

## Rules

- **Use `f.input` by default.** Drop to `f.input_field` + individual helpers only when Bootstrap's input-group layout requires it.
- **Use `as: :password` for sensitive fields** — renders `type="password"` server-side so the value is never exposed in plain text before JS runs.
- **Never skip `f.error_notification`.** Include both lines at the top of every form.
- **Use `hint:` option, not custom HTML divs.** The wrapper already outputs `<div class="form-text text-muted">`.
- **Manual error blocks need `d-block`.** `f.full_error` with `class: "invalid-feedback d-block"` when inside an input-group.
- **Don't add `mb-3` manually.** The `:default` wrapper already includes it.
- **Prefer I18n for labels/hints** on frequently reused attributes instead of repeating them inline.
