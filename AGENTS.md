# Repository Guidelines

## Project Overview

Reelix Manager is a Rails 8.1 application for managing a local video library (movies and TV shows). It provides:

- **Library scanning**: Indexes local video files and extracts metadata
- **TMDB integration**: Fetches metadata, posters, and episode information from The Movie Database
- **Resumable uploads**: tus protocol for large file uploads with pause/resume
- **GraphQL API**: Type-safe API for searching, uploading, and managing video metadata
- **OAuth 2.0**: Device authorization grant for Reelix client applications
- **Error tracking**: Custom error logging and monitoring system

## Architecture & Data Flow

### High-Level Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    Web Interface                             │
│  (Rails views + Stimulus controllers + Bootstrap 5)         │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  GraphQL API Layer                           │
│  (graphql-ruby + Doorkeeper OAuth + Scope enforcement)      │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  Service Layer                               │
│  (ApplicationService base class pattern)                     │
│  - Uploads::TusUploadService                                │
│  - Uploads::TmdbMetadataService                             │
│  - Uploads::PromoteFileService                              │
│  - VideoBlobs::UpsertFromUploadService                      │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  Active Job Layer                            │
│  (Solid Queue + Error tracking middleware)                   │
│  - LibraryScanJob                                           │
│  - TmdbMatcherJob                                           │
│  - VideoBlobTmdbSyncJob                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  Rails Models                                │
│  - VideoBlob (core library entity)                          │
│  - UploadSession (tus upload tracking)                      │
│  - Config (application settings)                            │
│  - ErrorEntry (error tracking)                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Modules

| Module | Purpose |
|--------|---------|
| `app/models/video_blob.rb` | Core entity representing a video file in the library |
| `app/models/upload_session.rb` | Tracks tus resumable uploads |
| `app/models/config.rb` | Application settings (movie/TV paths) |
| `app/models/error_entry.rb` | Error tracking and monitoring |
| `app/graphql/` | GraphQL API with resolvers, types, mutations |
| `app/services/` | Service objects for business logic |
| `app/jobs/` | Background jobs for async processing |
| `app/components/` | View components (ViewComponent) |
| `app/javascript/controllers/` | Stimulus controllers for interactivity |

### Data Flow Patterns

1. **Upload Flow**: `POST /files` (tus) → `UploadSession` → `finalizeUpload` mutation → `PromoteFileService` → `VideoBlob`
2. **Library Scan**: `LibraryScanJob` → scans filesystem → creates `VideoBlob` records
3. **TMDB Sync**: `VideoBlobTmdbSyncJob` → fetches metadata → updates `VideoBlob`
4. **GraphQL Queries**: Resolvers → `ScopeEnforceable` → `require_search!`/`require_upload!` → data access

## Key Directories

```
app/
├── controllers/          # Rails controllers (web UI)
├── graphql/              # GraphQL API (queries, mutations, types, resolvers)
│   ├── resolvers/        # Query resolvers
│   ├── mutations/        # Mutation operations
│   ├── types/            # GraphQL type definitions
│   ├── sources/          # DataLoader sources for batch loading
│   └── concerns/         # Shared GraphQL concerns (ScopeEnforceable)
├── models/               # ActiveRecord models
├── services/             # Service objects (business logic)
│   ├── uploads/          # Upload-related services
│   └── video_blobs/      # VideoBlob-related services
├── jobs/                 # Background jobs (Solid Queue)
├── components/           # ViewComponent UI components
├── javascript/           # Frontend JavaScript
│   └── controllers/      # Stimulus controllers
└── helpers/              # View helpers

config/
├── initializers/         # Rails initializers
├── environments/         # Environment-specific config

test/
├── factories/            # FactoryBot definitions
├── models/               # Model tests
├── services/             # Service tests
├── graphql/              # GraphQL tests
└── controllers/          # Controller tests

lib/
├── error_tracking.rb     # Error tracking middleware
└── tasks/                # Rake tasks
```

## Development Commands

### Prerequisites
- Ruby 3.3.1 (via rbenv or asdf)
- Node.js + npm
- SQLite 3

### Setup
```bash
bundle install
npm install
bin/rails db:prepare
```

### Running the Server
```bash
bin/dev          # Starts web server + CSS watcher via foreman
```

### Build Commands
```bash
npm run build:css     # Compile Sass to CSS
npm test              # Run JavaScript tests (Vitest)
```

### Test Commands
```bash
bin/rails test        # Run Ruby tests (Minitest)
npm test              # Run JavaScript tests
bin/rubocop           # Lint Ruby code
bundle exec steep check  # Type check with Steep
```

### Linting & Quality
```bash
bin/rubocop           # Ruby style checking (omakase)
bin/brakeman          # Security vulnerability scanning
bin/bundler-audit     # Gem security audit
bin/importmap audit   # JavaScript dependency audit
```

### Type Checking
```bash
bundle exec rbs-inline --opt-out --output=sig/generated  # Generate RBS from annotations
bundle exec steep check --log-level=fatal                # Type check
```

## Code Conventions & Common Patterns

### Ruby Style
- **Omakase**: Project uses `rubocop-rails-omakase` for Rails-recommended Ruby styling
- **Type Annotations**: Inline RBS type annotations using `#: (args) -> return_type` syntax
- **Frozen String Literal**: `# frozen_string_literal: true` at top of files

### Service Objects
All services inherit from `ApplicationService` which provides a class-level `.call` shortcut:

```ruby
class MyService < ApplicationService
  def initialize(arg1, arg2:)
    @arg1 = arg1
    @arg2 = arg2
  end
  
  def call
    # Business logic here
    # Return result hash or object
  end
end

# Usage:
MyService.call(arg1, arg2:)  # Class method (preferred)
MyService.new(arg1, arg2:).call  # Instance method
```

### GraphQL Patterns

#### Resolvers
```ruby
module Resolvers
  class MyResolver < Resolvers::BaseResolver
    type Types::MyType, null: false
    
    argument :id, Integer, required: true
    
    def resolve(id:)
      require_search!  # Enforce scope
      # Query logic
    end
  end
end
```

#### Mutations (Relay-style)
```ruby
module Mutations
  class MyMutation < Mutations::BaseMutation
    argument :id, String, required: true
    
    field :result, Types::ResultType, null: true
    field :errors, [String], null: false
    
    def ready?(id:)
      require_upload!  # Enforce scope
      true
    end
    
    def resolve(id:)
      # Mutation logic
      { result: ..., errors: [] }
    rescue => e
      { result: nil, errors: [e.message] }
    end
  end
end
```

#### Scope Enforcement
GraphQL operations require OAuth scopes via `ScopeEnforceable` module:
- `require_search!` - For read operations (queries)
- `require_upload!` - For write operations (mutations)

Session-based requests (browser GraphiQL) bypass scope checks.

### Error Handling Rules

**Critical Rule: Never swallow errors**

- **NEVER** rescue `StandardError` (or any exception) without re-raising it
- The **ONLY** exception is when you explicitly log the error AND re-raise it
- This prevents silent failures that are difficult to debug

**Correct Pattern:**

```ruby
rescue StandardError => e
  Rails.logger.error("Failed to do something: #{e.message}")
  Rails.logger.error(e.backtrace&.join("\n"))
  raise  # Always re-raise!
end
```

**Incorrect Pattern (DO NOT DO THIS):**

```ruby
rescue StandardError => e
  Rails.logger.error("Failed: #{e.message}")
  # Missing re-raise - error is swallowed!
  nil
end
```
range_end_pos_inclusive_marker_after_237#XP
content_pos_marker_after_237#XP

#### Application-Level Errors
```ruby
ErrorEntry.log_error(error, context)  # context: controller, job, or GraphQL context
```

Errors are stored in `error_entries` table with:
- Fingerprinting for grouping similar errors
- User context (if authenticated)
- Request/job context
- Sanitized params (sensitive values filtered)

#### Job Error Handling
`ApplicationJob` overrides `perform_now` to automatically catch and log errors:

```ruby
class ApplicationJob < ActiveJob::Base
  def perform_now(*args)
    super
  rescue StandardError => e
    store_error(e, args)
    raise  # Re-raise for ActiveJob handling
  end
end
```

### JavaScript Patterns

This project uses **Stimulus** for all JavaScript behavior with **Turbo** for navigation and **Import Maps** for module loading (no build step).

#### Creating Controllers

**Always use the Rails generator**: `bin/rails generate stimulus my_feature`

This creates `app/javascript/controllers/my_feature_controller.js` with identifier `my-feature` (underscores become hyphens).

**After generating a controller**:

1. Add a static import to `app/javascript/controllers/index.js`:

```javascript
import MyFeatureController from "controllers/my_feature_controller"
application.register("my-feature", MyFeatureController)
```

2. Run `bin/rails assets:precompile` so the importmap picks up the new file. This project uses precompiled static assets in `public/assets/` — new controllers are invisible to the browser until compiled.

3. For per-page controller loading (e.g., in development), use `content_for :page_scripts` in your view:

```erb
<% content_for :page_scripts do %>
  <script type="module">
    import { application } from "controllers/application"
    import MyFeatureController from "controllers/my_feature_controller"
    application.register("my-feature", MyFeatureController)
  </script>
<% end %>
```

#### Controller Structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]  // DOM elements
  static values = { url: String, count: { type: Number, default: 0 } }  // typed data

  connect() {
    // Called when controller connects to DOM; set initial state here
  }

  disconnect() {
    // Cleanup when controller disconnects
  }

  someAction(event) {
    this.inputTarget.value  // single target
    this.inputTargets       // all targets
    this.hasInputTarget     // boolean check
  }
}
```

#### HTML Wiring

```erb
<div data-controller="my-feature">
  <input data-my-feature-target="input" type="text" />
  <span data-my-feature-target="output"></span>
  <button data-action="my-feature#someAction">Go</button>
</div>
```

**Key data attributes**:

| Attribute | Purpose |
|-----------|---------|
| `data-controller="name"` | Mounts the controller |
| `data-name-target="targetName"` | Marks an element as a target |
| `data-action="name#method"` | Calls method on click (default event) |
| `data-action="input->name#method"` | Calls method on `input` event |
| `data-name-some-value="..."` | Passes a typed value |

#### Values for State

Values are typed properties passed from HTML that trigger callbacks when changed — use this for state-driven UI rather than reading the DOM:

```javascript
static values = { open: { type: Boolean, default: false } }

openValueChanged(value) {
  this.element.classList.toggle("hidden", !value)
}
```

```erb
<div data-controller="my-feature" data-my-feature-open-value="true">
```

#### Controller Rules

- **Never write inline `<script>` tags.** Move logic into controllers.
- **Never use `getElementById` or `querySelector` from a controller.** Use targets — they scope lookups and are Turbo-safe.
- **Never use private class field syntax (`#method`).** It can silently prevent module loading.
- **One controller per behavior.** Small, focused controllers are easier to reuse.
- **Use `connect()` for initial DOM state.** Set up initial state in `connect()` rather than value callbacks.
- **Controllers are Turbo-safe.** `connect()`/`disconnect()` fire correctly on Turbo navigation.

#### Testing (Vitest + Testing Library)

```javascript
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { screen } from '@testing-library/dom'
import MyController from './my_controller'
import { createStimulusTestHelper, simulateLocation } from '../test'

describe('MyController', () => {
  const helper = createStimulusTestHelper(MyController, 'my')

  beforeEach(async () => {
    await helper.start()
  })

  afterEach(() => {
    helper.stop()
  })

  it('does something', async () => {
    document.body.innerHTML = '<div data-controller="my">...</div>'
    await new Promise(resolve => setTimeout(resolve, 100))
    expect(screen.getByText('...')).toBeInTheDocument()
  })
}) 
```

**Note: `polling_controller.js` currently has no tests.** When adding new controllers, always include tests following the pattern in `hostname_controller_test.js`.

### Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Models | Snake case | `video_blob.rb`, `upload_session.rb` |
| Services | PascalCase in modules | `Uploads::TusUploadService` |
| Jobs | PascalCase | `LibraryScanJob` |
| GraphQL Types | PascalCase | `VideoBlobType`, `MovieType` |
| Stimulus Controllers | Snake case file, PascalCase class | `hostname_controller.js` → `HostnameController` |
| Test Files | `_test.js` suffix | `hostname_controller_test.js` |

### Database Enums
```ruby
enum :media_type, { movie: 0, tv: 1 }
enum :extra_type, EXTRA_TYPES.keys  # feature_films, trailers, etc.
enum :status, { unacknowledged: 0, acknowledged: 1, resolved: 2 }
```

## Important Files

| File | Purpose |
|------|---------|
| `config/routes.rb` | Route definitions including GraphQL, tus, OAuth endpoints |
| `config/initializers/doorkeeper.rb` | OAuth 2.0 configuration (scopes: all, search, upload) |
| `app/graphql/reelix_manager_schema.rb` | GraphQL schema configuration |
| `app/models/video_blob.rb` | Core domain model for video files |
| `app/services/application_service.rb` | Service object base class |
| `app/jobs/application_job.rb` | Job base class with error tracking |
| `app/javascript/controllers/index.js` | Stimulus controller registrations |
| `vitest.config.js` | JavaScript test configuration |
| `Dockerfile` | Production container build |

## Runtime/Tooling Preferences

### Runtime Requirements
- **Ruby**: 3.3.1 (enforced via `.ruby-version`)
- **Node.js**: 20.x (for build tools)
- **Package Manager**: npm (not yarn)
- **Database**: SQLite 3

### Build Tooling
- **Sass**: For CSS preprocessing (Bootstrap 5)
- **Import Maps**: For JavaScript module loading (no bundler)
- **Propshaft**: Rails asset pipeline

### Type System
- **RBS**: Ruby type signatures
- **Steep**: Static type checker
- **rbs-inline**: Generates RBS from inline annotations

### Background Jobs
- **Solid Queue**: Database-backed job processing
- **Mission Control**: Job monitoring UI (`/jobs`, admin only)

## Testing & QA

### Ruby Testing
- **Framework**: Minitest (Rails default)
- **Factories**: FactoryBot
- **Matchers**: Shoulda Matchers
- **Parallelization**: Enabled (`parallelize(workers: :number_of_processors)`)

#### Running Tests
```bash
bin/rails test                    # All tests
bin/rails test test/models/       # Specific directory
bin/rails test:system             # System tests (Selenium)
```

### JavaScript Testing
- **Framework**: Vitest
- **DOM Testing**: @testing-library/dom
- **Matchers**: @testing-library/jest-dom
- **Environment**: jsdom

#### Running Tests
```bash
npm test              # Run all JS tests
```

### CI Pipeline (GitHub Actions)
1. **scan_ruby**: Brakeman + bundler-audit
2. **scan_js**: Importmap audit
3. **test_js**: Vitest tests
4. **lint**: RuboCop with GitHub annotations
5. **test**: Ruby tests
6. **system-test**: Selenium system tests
7. **type_check**: Steep type checking + coverage

### Test Helpers

#### Ruby SQL Query Counter
```ruby
def count_sql_queries(&block)
  # Counts real SELECT queries, excluding SCHEMA/CACHE/transactions
end
```

#### JavaScript Stimulus Test Helper
```javascript
const helper = createStimulusTestHelper(MyController, 'my')
await helper.start()
// ... test ...
helper.stop()
```

### Coverage Expectations
- Type coverage checked via `test/type_coverage_test.rb`
- All new code should have type annotations
- Critical paths should have unit tests

## API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/graphql` | POST | GraphQL API (queries + mutations) |
| `/files` | POST/PATCH/HEAD/DELETE | tus resumable uploads |
| `/oauth/token` | POST | OAuth token endpoint |
| `/oauth/device_authorization` | GET/POST | Device authorization grant |
| `/graphiql` | GET | GraphQL IDE (admin only) |
| `/jobs` | GET | Job monitoring (admin only) |

## GraphQL API

### Queries
- `searchMulti` - Search movies and TV shows via TMDB
- `movie(id)` - Fetch movie details from TMDB
- `tv(id)` - Fetch TV show details from TMDB
- `season(id)` - Fetch season with episodes
- `videoBlobs(mediaType, tmdbId)` - List local video files
- `uploadSessions` - List active tus uploads
- `node(id)` / `nodes(ids)` - Global ID lookup

### Mutations
- `finalizeUpload` - Complete a tus upload and create VideoBlob

### Scopes
- `all` - Unrestricted access
- `search` - Read operations (queries)
- `upload` - Write operations (mutations)

## Type Checking

This project uses **rbs-inline** with inline annotations in Ruby source files to generate RBS signatures under `sig/generated/`, checked by **Steep**.

### Rules

- **Never use `untyped` to fix type errors.** It silences the checker without resolving the problem.
- **Never use `# steep:ignore` to suppress type mismatch errors.** Fix the actual types instead.
- **`# steep:ignore` is only permitted for genuine Steep limitations** (e.g., `NoMethod` on dynamic framework methods). Always add a comment explaining why the type cannot be expressed.
- **Always define types.** Every method parameter, return value, and instance variable must be typed.
- **Annotate with `#:` inline in the Ruby source file** — do not hand-edit files under `sig/generated/` (they are regenerated).
- **Regenerate signatures after any annotation change:** `bundle exec rbs-inline --opt-out --output=sig/generated`
- **Verify with Steep:** `bundle exec steep check` (baseline is 0 errors; framework warnings from graphql-ruby/Doorkeeper are expected noise).

### Annotation Examples

```ruby
#: (String path) -> void
def load_file(path)
  # ...
end

#: (String | Integer) -> String
def format(value)
  value.to_s
end

#: (String?) -> void
def process(value)
  # ...
end
```

### What to Use Instead of `untyped`

| Situation | Use Instead |
|-----------|-------------|
| Value might be nil | `Type?` (nilable) |
| Multiple valid types | `TypeA \| TypeB` (union) |
| Array of a type | `Array[Type]` |
| Hash with typed keys/values | `Hash[KeyType, ValueType]` |
| Unknown gem type missing RBS | Add gem to `rbs_collection.yaml` or write a stub under `sig/` |

## TMDB API Usage

Use these rules when calling The Movie Database (TMDB) API.

### Base URLs

- TMDB API (v3): `https://api.themoviedb.org/3`
- TMDB images: `https://image.tmdb.org/t/p/` (final URL includes a size segment like `w500` and the returned `file_path`).

### Authentication

Prefer **Bearer token** auth: `Authorization: Bearer <TMDB_API_READ_ACCESS_TOKEN>`

Legacy alternative: `api_key=<TMDB_API_KEY>` query param is also supported for v3.

### Efficient Fetching

Use `append_to_response` to reduce multiple round trips for detail endpoints:

```
/movie/{id}?append_to_response=videos,images
```

Max appended remote calls is 20.

### Images

To build a full image URL:

1. Cache `/configuration` aggressively (rarely changes) to get `base_url` and supported `file_size` values.
2. Construct URL: `{base_url}{size}{file_path}` (example: `https://image.tmdb.org/t/p/w500/poster_path`).

### Rate Limiting

- Legacy limit (40 requests / 10 seconds) is disabled, but TMDB enforces upper limits (~40 req/sec). Respect `429`.
- Implement short exponential backoff + jitter on 429.
- Add client-side limiter for burst control in batch workloads.

### Error Handling

| Status | Action |
|--------|--------|
| 401 | Surface "invalid/expired token"; don't retry |
| 404 | Return null/empty result; don't retry |
| 422/400 | Treat as developer error; include details |
| 429 | Retry with backoff; reduce concurrency |
| 5xx/503/504 | Retry with backoff up to small max; then fail |

## Simple Form

This project uses **simple_form** 5.x with Bootstrap 5.

### Basic Form Structure

```erb
<%= simple_form_for @record, url: url, method: @record.persisted? ? :patch : :post do |f| %>
  <%= f.error_notification %>
  <%= f.error_notification message: f.object.errors[:base].to_sentence if f.object.errors[:base].present? %>

  <%= f.input :name %>
  <%= f.input :email %>

  <%= f.button :submit, class: "btn btn-primary" %>
<% end %>
```

### `f.input` — Standard Building Block

`f.input` renders the full Bootstrap wrapper: label + input + hint + inline errors.

```erb
<%= f.input :title %>
<%= f.input :movie_path, label: "Movie Directory", hint: "Absolute path" %>
<%= f.input :description, as: :text %>
<%= f.input :api_key, as: :password %>
<%= f.input :notes, input_html: { rows: 4 } %>
<%= f.input :name, wrapper_html: { class: "col-md-6" } %>
```

### Individual Component Helpers

Use these when you need to break out of the full wrapper (e.g., inside a Bootstrap input-group):

```erb
<%= f.label    :api_key, "API Key", class: "form-label" %>
<%= f.input_field :api_key, as: :password %>
<%= f.hint     "Your TMDB API key" %>
<%= f.full_error :api_key, class: "invalid-feedback d-block" %>
```

### Bootstrap Input-Group with Stimulus

```erb
<div class="mb-3" data-controller="reveal">
  <%= f.label :api_key, "API Key", class: "form-label" %>
  <div class="input-group">
    <%= f.input_field :api_key,
                      as: :password,
                      class: "form-control",
                      data: { "reveal-target": "field" } %>
    <button type="button" class="btn btn-outline-secondary"
            data-reveal-target="showButton"
            data-action="reveal#show">Show</button>
  </div>
  <%= f.full_error :api_key, class: "invalid-feedback d-block" %>
  <%= f.hint "Your API key from TMDB." %>
</div>
```

### Rules

- **Use `f.input` by default.** Drop to `f.input_field` only when Bootstrap's input-group layout requires it.
- **Use `as: :password` for sensitive fields** — renders `type="password"` server-side.
- **Never skip `f.error_notification`.** Include both lines at the top of every form.
- **Use `hint:` option, not custom HTML divs.** The wrapper already outputs `<div class="form-text text-muted">`.
- **Manual error blocks need `d-block`.** `f.full_error` with `class: "invalid-feedback d-block"` inside input-groups.

## Media Upload Path System

### End-to-End Flow

1. Client → `POST /files` (tus starts upload, returns upload UID)
2. Client → `PATCH /files/:uid` (tus receives chunks; stored in `tmp/tus_uploads/:uid`)
3. Client → `FinalizeUpload` mutation with `upload_id`, `tmdb_id`, `media_type` (+ season/episode for TV)

Server-side (`FinalizeUpload`):

a. Validate tus upload is 100% complete.
b. Validate required arguments (TV needs `season_number` + `episode_number`).
c. Create unsaved `VideoBlob` with metadata.
d. Fetch title, year, poster, and (TV) episode title from TMDB.
e. Ask blob for generated filename and absolute `media_path`.
f. Move file: `tmp/tus_uploads/:uid` → `tmp/media_staging/:uuid.:ext` (staging)
g. Delete tus metadata.
h. `mkdir_p` the final directory.
i. Move file: `tmp/media_staging/:uuid.:ext` → final destination
j. `find_or_initialize_by(key:)` on `VideoBlob`, populate fields, save.

### Path Construction

Paths are built from `VideoBlob` using `Config::Video.newest` for movie/TV roots.

**Movie**:

```
{movie_path}/{Title (Year)}/
  {Title (Year)}.ext
```

**TV Episode**:

```
{tv_path}/{Show (Year)}/Season XX/
  {Show (Year)} - sXXeYY - Episode Title.ext
```

Season and episode numbers are **zero-padded to two digits**. Episode title segment is omitted if unavailable.

### VideoBlob Helper Methods

- `media_name` — canonical display name (no path, no extension): `"Batman Begins (2005)"` or `"Breaking Bad (2008) - s01e01"`
- `generated_filename` — final basename: `"Batman Begins (2005).mkv"`
- `directory` — absolute destination directory
- `media_path` — final absolute path

### Required Config

- `settings_movie_path` — absolute path to movie library root
- `settings_tv_path` — absolute path to TV library root
- `settings_tmdb_api_key` — API key for TMDB lookups

## Turbo + ViewComponent + Stimulus

Use this pattern when a page should keep its outer shell stable and only refresh dynamic regions.

### Recommended Controller Shape

```ruby
class ItemsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @items = load_items

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def load_items
    Item.search(@query).order(:name).load.to_a
  end
end
```

### Recommended View Structure

`index.html.erb`:

```erb
<%= turbo_frame_tag "items_count" do %>
  <%= render Items::CountComponent.new(count: @items.size) %>
<% end %>

<%= turbo_frame_tag "items_controls" do %>
  <%= render Items::ControlsComponent.new(query: @query) %>
<% end %>

<%= turbo_frame_tag "items_results" do %>
  <%= render Items::ResultsComponent.new(items: @items) %>
<% end %>
```

`index.turbo_stream.erb`:

```erb
<%= turbo_stream.update "items_count", method: :morph do %>
  <%= render Items::CountComponent.new(count: @items.size) %>
<% end %>

<%= turbo_stream.update "items_results", method: :morph do %>
  <%= render Items::ResultsComponent.new(items: @items) %>
<% end %>
```

### Turbo Stream Actions

Turbo Stream provides eight actions for manipulating the DOM:

| Action | Purpose |
|--------|---------|
| `append` | Appends content to the container designated by the target id |
| `prepend` | Prepends content to the container designated by the target id |
| `replace` | Replaces the entire element designated by the target id (removes the target element itself) |
| `update` | Updates the **inner content** within the container designated by the target id (preserves the target element) |
| `remove` | Removes the element designated by the target id |
| `before` | Inserts content before the element designated by the target id |
| `after` | Inserts content after the element designated by the target id |
| `refresh` | Initiates a page refresh |

**Critical: Use `update` not `replace` for polling/refreshing content.** `replace` removes the target element entirely, so subsequent Turbo Stream responses have nothing to target. `update` preserves the target element and only replaces its inner HTML, making it safe for repeated updates.

**Use `method: :morph` with `update` for efficient DOM updates.** Morphing compares the old and new HTML and only modifies nodes that actually changed, preserving user input state, focus, and minimizing reflows. Default `update` replaces all inner HTML unconditionally.

Example:

```erb
<%# index.html.erb - define the target element %>
<%= turbo_frame_tag "active_uploads" do %>
  <%= render Uploads::ActiveUploadsComponent.new(active_uploads: @active_uploads) %>
<% end %>

<%# index.turbo_stream.erb - morph inner content, preserve unchanged nodes %>
<%= turbo_stream.update "active_uploads", method: :morph do %>
  <%= render Uploads::ActiveUploadsComponent.new(active_uploads: @active_uploads) %>
<% end %>
```

### Rules

- Give every replaceable region a stable DOM id (use `turbo_frame_tag`).
- Use `turbo_stream.update` with `method: :morph` for polling/refreshing content.
- Use `turbo_stream.replace` only when you intentionally want to replace the entire element.
- Keep controls outside Turbo Stream updates unless the response must change the control markup.
- Stimulus manages local UI state (active tabs, hidden fields, debounced submit), not server rendering.
### Turbo GET Forms

```erb
<%= form_with url: items_path, method: :get,
              data: { turbo_stream: true, controller: "submit-on-keyup" } do |f| %>
```

Set `data-turbo-stream="true"` on GET forms that should receive Turbo Stream responses.

### Testing

- **Component tests** for markup contracts (count text, empty state, rendered cards).
- **Controller tests** for Turbo Stream wiring (HTML render, Stream response content type, expected targets updated).

**Critical: Rails respond_to format order.** Rails checks formats in declaration order. When the Accept header includes multiple MIME types (e.g., `text/vnd.turbo-stream.html, text/html`), Rails matches the first compatible format. **Always declare `format.turbo_stream` before `format.html`** to ensure Turbo Stream responses are selected when both are acceptable.

**Critical: Accept header must not contain `*/*`.** If the Accept header includes `*/*` (e.g., `text/vnd.turbo-stream.html, text/html,*/*`), Rails treats the request as browser-like and ignores the Accept header, defaulting to HTML. Use `'Accept': 'text/vnd.turbo-stream.html, text/html'` without the wildcard.