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

### Error Handling

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

#### Stimulus Controllers
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["element"]
  
  connect() {
    // Initialization logic
  }
}
```

#### Explicit Registration
Controllers are explicitly registered in `app/javascript/controllers/index.js`:
```javascript
import MyController from "controllers/my_controller"
application.register("my", MyController)
```

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
