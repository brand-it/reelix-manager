---
id: create-service
description: Create new service objects following Rails patterns for type checking, testing, and maintainability. Use when asked to create a new service.
---

## Rules

1. **Extend ApplicationService**: All services must inherit from `ApplicationService` to get the class-level `.call` shortcut
2. **Type-checked**: All services must have inline `#:` type annotations that generate valid RBS signatures
3. **Tested**: Every service requires a corresponding test file at `test/services/<path>/<service_name>_test.rb`
4. **Single responsibility**: Each service should do one thing well

## Required Service Structure

```ruby
# frozen_string_literal: true

class MyService < ApplicationService
  #: (arg1_type, ?arg2_type?) -> void
  def initialize(arg1, arg2 = nil)
    @arg1 = arg1
    @arg2 = arg2
  end

  #: () -> return_type
  def call
    # Business logic here
    # Return result hash or object
  end

  # Optional: private helper methods
  private

  #: () -> helper_return_type
  def helper_method
    # Implementation
  end
end
```

## Critical: Type Annotation Syntax

### Positional Arguments (REQUIRED)

Use **positional argument syntax** for type annotations:

```ruby
#: (StandardError, ?untyped?) -> ErrorEntry
def call(error, context = nil)
  # This works correctly with Steep
end
```

### Keyword Arguments (NOT SUPPORTED)

**Do NOT use keyword argument syntax** - it is not supported by `rbs-inline`:

```ruby
# WRONG - This will cause Steep errors
#: (error: StandardError, ?context: untyped?) -> ErrorEntry
def call(error, context = nil)
  # Steep cannot parse this correctly
end
```

### Why This Matters

The `rbs-inline` tool generates RBS signatures from inline annotations. It expects positional parameter syntax:
- `?Type?` for optional parameters (default value required)
- `Type` for required parameters
- Parameters are matched by position, not by name

If you use keyword syntax (`name: Type`), Steep will report `MethodDefinitionMissing` errors because the generated RBS doesn't match the actual method signature.

## Type Checking Workflow

### Step 1: Write Service with Annotations

Add inline `#:` annotations to your service:

```ruby
#: (String, Integer) -> void
def initialize(path, count)
  @path = path
  @count = count
end

#: () -> Hash
def call
  { path: @path, count: @count }
end
```

### Step 2: Regenerate RBS

```bash
bin/rails type_check:gen
# Or: bundle exec rbs-inline --opt-out --output=sig/generated
```

This scans all Ruby files and generates RBS signatures in `sig/generated/`.

### Step 3: Verify Type Checking

```bash
bin/rails type_check:check
# Or: bundle exec steep check --log-level=fatal
```

If errors occur, fix them before proceeding.

### Step 4: Handle MethodDefinitionMissing Errors

If you see errors like:

```
sig/generated/my_service.rbs:5:0: MethodDefinitionMissing
  error: Method #call is not defined in the following interface(s):
  
    MyService
```

This means the RBS signature doesn't match the actual method. Add an ignore comment in `lib/tasks/type_check.rake`:

```ruby
# In lib/tasks/type_check.rake, within the steep_check task
ignore_paths << "sig/generated/my_service.rbs"
```

Then re-run type checking.

## Common Type Patterns

| Pattern | Annotation | Ruby Code |
|---------|------------|-----------|
| Required param | `Type` | `def foo(bar)` |
| Optional param | `?Type?` | `def foo(bar = nil)` |
| Void return | `-> void` | `def foo; end` |
| Hash return | `-> Hash` | `def foo; {}; end` |
| Array return | `-> [Type]` | `def foo; []; end` |
| Nullable return | `-> ?Type` | `def foo; nil; end` |
| Union return | `-> Type1 \| Type2` | `def foo; ...; end` |

## Complete Working Example

### Service: ErrorLoggerService

```ruby
# frozen_string_literal: true

class ErrorLoggerService < ApplicationService
  #: (StandardError, ?untyped?) -> void
  def initialize(error, context = nil)
    @error = error
    @context = context
  end

  #: () -> ErrorEntry
  def call
    ErrorEntry.log_error(@error, @context)
  end
end
```

### Test: ErrorLoggerServiceTest

```ruby
# frozen_string_literal: true

require "test_helper"

class ErrorLoggerServiceTest < ApplicationSystemTestCase
  test "logs error and returns ErrorEntry" do
    error = StandardError.new("test error")
    
    result = ErrorLoggerService.call(error)
    
    assert_instance_of(ErrorEntry, result)
    assert_equal("test error", result.message)
  end

  test "logs error with context" do
    error = StandardError.new("test error")
    context = { controller: "TestController" }
    
    result = ErrorLoggerService.call(error, context)
    
    assert_instance_of(ErrorEntry, result)
  end
end
```

### Usage

```ruby
# Class-level call (preferred)
ErrorLoggerService.call(error, context)

# Instance-level call
ErrorLoggerService.new(error, context).call
```

## Verification Checklist

Before marking a service complete:

- [ ] Service extends `ApplicationService`
- [ ] `#initialize` has `#: (...) -> void` annotation
- [ ] `#call` has `#: () -> ReturnType` annotation
- [ ] Uses positional argument syntax (not keyword)
- [ ] RBS regenerated with `bin/rails type_check:gen`
- [ ] Type checking passes with `bin/rails type_check:check`
- [ ] Test file exists at `test/services/<path>/<service_name>_test.rb`
- [ ] Tests pass with `bin/rails test`
- [ ] No RuboCop violations (`bin/rubocop app/services/<path>/<service_name>.rb`)

## Troubleshooting

### Error: MethodDefinitionMissing

**Symptom:**
```
sig/generated/service_name.rbs:X:0: MethodDefinitionMissing
```

**Cause:** RBS signature doesn't match the actual method definition.

**Fix:**
1. Verify you're using positional argument syntax
2. Check that optional parameters have default values
3. If still failing, add ignore path in `lib/tasks/type_check.rake`

### Error: ArgumentTypeMismatch

**Symptom:**
```
app/services/service_name.rb:X:Y: ArgumentTypeMismatch
  error: Expected: TypeA
  actual: TypeB
```

**Cause:** Method called with wrong argument type.

**Fix:**
1. Update the call site to pass the correct type
2. Or update the type annotation if it's too restrictive

### Error: ReturnTypesMismatch

**Symptom:**
```
app/services/service_name.rb:X:Y: ReturnTypesMismatch
  error: Expected: TypeA
  actual: TypeB
```

**Cause:** Method returns different type than annotated.

**Fix:**
1. Update return type annotation to match actual return
2. Or update the method to return the annotated type

### Error: Cannot Determine Type

**Symptom:**
```
app/services/service_name.rb:X:Y: CannotDetermineType
```

**Cause:** Steep cannot infer the type of a variable or expression.

**Fix:**
1. Add explicit type annotation: `var #: Type = value`
2. Or use `untyped` if type is truly dynamic

## File Locations

| Item | Path |
|------|------|
| Services | `app/services/<module>/<service_name>.rb` |
| Tests | `test/services/<module>/<service_name>_test.rb` |
| Base class | `app/services/application_service.rb` |
| Type check task | `lib/tasks/type_check.rake` |
| Generated RBS | `sig/generated/` |

## Related Skills

- `type-check` - Fix Steep type errors and manage RBS signatures