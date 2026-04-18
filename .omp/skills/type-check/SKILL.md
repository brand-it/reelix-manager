---
id: type-check
description: Fix Steep type errors in the Ruby codebase. Use this when asked to fix type errors, add type annotations, or manage Steep type checking.
---

When asked to fix Steep type errors or manage type annotations, follow this process exactly.

## Step 1 — Regenerate and run type-check

Always start by regenerating RBS files and seeing the current errors:

```bash
bin/type-check
```

This command runs three steps:
1. `bundle exec rbs_rails all` - Generates Rails signatures in `sig/rbs_rails/`
2. `bundle exec rails type_check:gen` - Regenerates `sig/generated/` from `#:` annotations
3. `bundle exec steep check --verbose` - Runs Steep type checker

**Never modify files in `sig/generated/` or `sig/rbs_rails/` directly** - they are auto-generated.

## Step 2 — Prompt user to select an error

If the user did not specify a particular error to fix, use the `ask` tool to present the top errors from `bin/type-check` output:

```
ask({
  questions: [{
    id: "select-error",
    question: "Which Steep type error would you like to fix?",
    options: [
      { label: "app/models/error_entry.rb:110 - unique_error_classes return type mismatch (ActiveRecord_Relation vs Array)" },
      { label: "app/models/error_entry.rb:124 - JSON.parse(nil) argument type mismatch" },
      { label: "app/services/key_parser_service.rb:116 - Config does not have settings_movie_path" },
      { label: "app/graphql/mutations/finalize_upload.rb:54 - Unexpected keyword argument" },
      { label: "Skip and just run type-check" }
    ],
    recommended: 0
  }],
  _i: "Presenting type errors for user selection"
})
```

If the user specified an error, first diagnose it. Read the Steep output and identify the error type:

| Error | Cause | Fix |
|---|---|---|
| `FalseAssertion` | `#: Type` annotation doesn't match inferred type | Update annotation or fix code |
| `NoMethod` | Method doesn't exist on the type | Use correct type (e.g., `Config::Video` vs `Config`) |
| `UnexpectedPositionalArgument` | Wrong argument style | Change to keyword argument |
| `MethodDefinitionMissing` | Method in RBS but not Ruby | Use `untyped` for the type or update RBS signature |
| `ArgumentTypeMismatch` | Argument type incompatible with parameter | Fix argument or parameter type |
| `IncompatibleAssignment` | Assignment type doesn't match variable type | Fix type annotation or code |
| `MethodBodyTypeMismatch` | Method body return type doesn't match annotation | Fix annotation or return value |

## Step 3 — Ask user for approach

Before fixing, use the `ask` tool to prompt the user which approach to take. Example:

```
ask({
  questions: [{
    id: "approach",
    question: "How would you like to fix this Steep type error?",
    options: [
      { label: "Fix the code - Update the implementation to match the type annotation" },
      { label: "Fix the annotation - Update the #: annotation to match the code" }
    ],
    recommended: 0
  }],
  _i: "Asking user for fix approach"
})
```

Wait for user confirmation before proceeding.

## Step 4 — Fix one error at a time

Fix errors sequentially, one at a time. After each fix:

1. Run `bin/type-check` to verify the fix
2. If more errors remain, use the `ask` tool to present remaining errors and let user choose which to fix next:
   ```
   ask({
     questions: [{
       id: "next-error",
       question: "Error fixed. Which error would you like to fix next?",
       options: [
         { label: "app/models/error_entry.rb:124 - JSON.parse(nil) argument type mismatch" },
         { label: "app/models/error_entry.rb:133 - JSON.parse(nil) argument type mismatch" },
         { label: "app/services/key_parser_service.rb:116 - Config does not have settings_movie_path" },
         { label: "Stop fixing errors" }
       ],
       recommended: 0
     }],
     _i: "Presenting remaining type errors for selection"
   })
   ```
3. Continue until user chooses to stop or all errors are resolved

## Step 5 — Common fix patterns

### Fix instance variable type

Wrong:
```ruby
# @rbs @video_config: Config
```

Right:
```ruby
# @rbs @video_config: Config::Video
```

### Fix method annotation

Wrong:
```ruby
#: () -> Config
def video_config
  # ...
end
```

Right:
```ruby
#: () -> Config::Video
def video_config
  # ...
end
```

### Fix argument style

Wrong:
```ruby
#: (String) -> void
def process(name)
```

Right (if method expects keyword arg):
```ruby
#: (name: String) -> void
def process(name:)
```

### Use untyped for complex types

When a method accepts multiple different types or the type is too complex to express:

```ruby
#: (StandardError, ?untyped) -> ErrorEntry
def self.log_error(error, context = nil)
```

Or for return types that vary:

```ruby
#: (untyped) -> untyped
def sanitize_params(params)
```

## Step 6 — Verify the fix

After all fixes are complete, run:

```bash
bin/type-check
```

Verify that `No problems detected` is shown or that remaining errors are expected and documented.

## RBS Syntax Reference

### Types

```rbs
_type_ ::= _class-name_ _type-arguments_                     (Class instance type)
         | _interface-name_ _type-arguments_                 (Interface type)
         | _alias-name_ _type-arguments_                     (Alias type)
         | `singleton(` _class-name_ `)` _type-arguments_    (Class singleton type)
         | _literal_                                         (Literal type)
         | _type_ `|` _type_                                 (Union type)
         | _type_ `&` _type_                                 (Intersection type)
         | _type_ `?`                                        (Optional type)
         | `{` _record-name_ `:` _type_ `,` etc. `}`         (Record type)
         | `[]` | `[` _type_ `,` etc. `]`                    (Tuples)
         | _type-variable_                                   (Type variables)
         | `self`
         | `instance`
         | `class`
         | `bool`
         | `untyped`
         | `nil`
         | `top`
         | `bot`
         | `void`
         | _proc_                                        (Proc type)
```

#### Base Types

| Type | Description |
|------|-------------|
| `self` | Type of receiver (self-context only) |
| `instance` | Type of instance of the class (classish-context only) |
| `class` | Singleton of the class (classish-context only) |
| `bool` | Alias of `true \| false` |
| `untyped` | Dynamic type (like `any` in TypeScript) |
| `nil` | Nil value |
| `top` | Supertype of all types |
| `bot` | Subtype of all types |
| `void` | Supertype of all types (use for return values not used) |
| `boolish` | Alias of `top`, use for truthiness checks |

#### Type Examples

```rbs
Integer                      # Instance of Integer class
::Integer                    # Instance of ::Integer class
Hash[Symbol, String]         # Hash with type application
_ToS                         # Interface type
singleton(String)            # Class singleton type
Integer | String             # Union type
Integer?                     # Optional type (Integer | nil)
{ id: Integer, name: String } # Record type
[String, Integer]            # Tuple type
```

### Method Types

```rbs
_method-type_ ::= _parameters?_ _block?_ `->` _type_
```

#### Parameters

```rbs
() -> String                             # No parameters
(Integer) -> String                      # Required positional
(?Integer) -> String                     # Optional positional
(*Integer) -> String                     # Rest positional
(Integer, ?String) -> String             # Mixed positionals
(name: String) -> String                 # Required keyword
(?name: String) -> String                # Optional keyword
(name: String, **rest) -> String         # Rest keyword
(size: Integer sz) -> String             # Keyword with variable name
```

#### Block Parameters

```rbsn
() { (Integer) -> String } -> void       # Required block
?{ (Integer) -> String } -> void         # Optional block
```

### Inline Annotations (#: syntax)

#### Method Annotations

```ruby
#: () -> void
def noop
end

#: (String) -> String
def process(name)
  name.upcase
end

#: (name: String, ?age: Integer?) -> String
def greet(name:, age: nil)
  "#{name}#{age ? ", #{age}" : ''}"
end

#: () -> Hash[Symbol, untyped]
def data
  { name: 'test' }
end

#: (*untyped) -> untyped
def forward(...)
  # Use for argument forwarding when types are complex
end
```

#### Instance Variable Annotations

```ruby
# @rbs @name: String
# @rbs @count: Integer?
```

#### Class Method Annotations

```ruby
class << self
  #: (String) -> void
  def create(name)
  end
end
```

### Common Type Patterns

#### Union Types

```ruby
#: () -> String | nil
def maybe_string
  condition ? 'yes' : nil
end

#: () -> String?
def maybe_string_shortcut
  condition ? 'yes' : nil
end
```

#### Record Types (Hash with fixed keys)

```ruby
#: () -> { id: Integer, name: String }
def user_record
  { id: 1, name: 'John' }
end
```

#### Tuple Types

```ruby
#: () -> [Integer, String]
def pair
  [1, 'hello']
end
```

#### Proc Types

```ruby
#: ^(Integer) -> String
def make_proc
  ->(n) { n.to_s }
end

#: () -> ^(Integer, String) -> bool
def make_binary_pred
  ->(a, b) { a > 0 && b.present? }
end
```

### Contextual Limitations

- `void` only allowed as return type or generic parameter
- `self` only allowed in self-context (instance methods, attributes)
- `class`/`instance` only allowed in classish-context (class bodies)

### Error Type Quick Reference

| Error | Typical Fix |
|-------|-------------|
| `NoMethod` | Use correct type (`Config::Video` vs `Config`) |
| `MethodDefinitionMissing` | Use `untyped` for the type or update RBS signature |
| `ArgumentTypeMismatch` | Fix argument type or add `.to_s`/`.to_i` |
| `MethodBodyTypeMismatch` | Fix return type annotation or return value |
| `IncompatibleAssignment` | Fix variable type annotation |
| `UnexpectedPositionalArgument` | Change to keyword argument `arg:` |
| `UnexpectedKeywordArgument` | Change to positional argument `arg` |
| `FalseAssertion` | Update type annotation to match code |
