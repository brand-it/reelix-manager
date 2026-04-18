---
id: rails-controller-testing
description: Patterns and best practices for testing Rails controllers using Test::Unit and Factory Bot
---

# Rails Controller Testing Skill

This skill provides patterns and best practices for testing Rails controllers using Test::Unit and Factory Bot.

## Setup

### Test Class Structure

```ruby
require "test_helper"

class MyControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular_user = users(:regular)
    @resource = build(:my_resource)
  end
end
```

### Using Factory Bot

Create factories in `test/factories/my_resources.rb`:

```ruby
FactoryBot.define do
  factory :my_resource do
    name { "Default Resource" }
    status { :active }
  end
end
```

Use factories in tests:

```ruby
# Create in database
@resource = create(:my_resource)

# Build without saving
@resource = build(:my_resource)

# Create with specific attributes
@resource = create(:my_resource, name: "Custom", status: :inactive)

# Create multiple
resources = create_list(:my_resource, 5)
```

## Authentication Testing

### Require Authentication

```ruby
test "should require authentication for index" do
  get my_resources_url
  assert_redirected_to new_user_session_path
end

test "should require authentication for show" do
  get my_resource_url(build(:my_resource))
  assert_redirected_to new_user_session_path
end
```

### Sign In User

Use `sign_in` helper (from Devise) instead of `as:` parameter:

```ruby
test "should allow authenticated users to access index" do
  sign_in @admin
  get my_resources_url
  assert_response :success
end
```

**Important:** Never use `as: @admin` parameter - this doesn't work for controller tests. Always use `sign_in`.

## Authorization Testing

### Admin-Only Access

```ruby
test "should deny access to non-admin users" do
  sign_in @regular_user
  get my_resources_url
  assert_redirected_to root_path
end

test "should allow admin users to access" do
  sign_in @admin
  get my_resources_url
  assert_response :success
end
```

## Testing Actions with Factory Bot

### Index Action

```ruby
test "should display resources in index" do
  create_list(:my_resource, 3)
  
  sign_in @admin
  get my_resources_url
  assert_response :success
  assert_select "table"
  assert_select "tr"
end

test "should filter by status" do
  create(:my_resource, status: :active)
  create(:my_resource, status: :inactive)
  
  sign_in @admin
  get my_resources_url, params: { status: "active" }
  assert_response :success
end
```

### Show Action

```ruby
test "should show resource details" do
  @resource = create(:my_resource, name: "Test Resource")
  
  sign_in @admin
  get my_resource_url(@resource)
  assert_response :success
  assert_select "h2", "Test Resource"
end

test "should redirect when resource not found" do
  sign_in @admin
  get my_resource_url(id: 99999)
  assert_redirected_to my_resources_url
end
```

### Create Action

```ruby
test "should create resource with valid params" do
  sign_in @admin
  
  assert_difference("MyResource.count") do
    post my_resources_url, params: {
      my_resource: attributes_for(:my_resource)
    }
  end
  
  assert_redirected_to my_resource_url(MyResource.last)
  assert_not_nil flash[:notice]
end

test "should not create resource with invalid params" do
  sign_in @admin
  
  assert_no_difference("MyResource.count") do
    post my_resources_url, params: {
      my_resource: { name: "" }
    }
  end
  
  assert_response :unprocessable_content
  assert_select ".alert"
end
```

### Update Action

```ruby
test "should update resource with valid params" do
  @resource = create(:my_resource)
  
  sign_in @admin
  
  patch my_resource_url(@resource), params: {
    my_resource: attributes_for(:my_resource, name: "Updated Name")
  }
  
  assert_redirected_to my_resource_url(@resource)
  @resource.reload
  assert_equal "Updated Name", @resource.name
end

test "should not update resource with invalid params" do
  @resource = create(:my_resource)
  
  sign_in @admin
  
  patch my_resource_url(@resource), params: {
    my_resource: { name: "" }
  }
  
  assert_response :unprocessable_content
  @resource.reload
  assert_equal "Original Name", @resource.name
end
```

### Destroy Action

```ruby
test "should destroy resource" do
  @resource = create(:my_resource)
  
  sign_in @admin
  
  assert_difference("MyResource.count", -1) do
    delete my_resource_url(@resource)
  end
  
  assert_redirected_to my_resources_url
  assert_not_nil flash[:notice]
end
```

## HTTP Methods

Use appropriate HTTP verb helpers:

```ruby
get    my_resources_url          # Index
get    my_resource_url(@resource) # Show
new_my_resource_url              # New (GET)
post   my_resources_url          # Create
edit_my_resource_url(@resource)  # Edit (GET)
patch  my_resource_url(@resource) # Update
delete my_resource_url(@resource) # Destroy
```

## Testing Flash Messages

```ruby
test "should set flash notice on success" do
  @resource = create(:my_resource)
  
  sign_in @admin
  delete my_resource_url(@resource)
  assert_redirected_to my_resources_url
  follow_redirect!
  assert_select ".alert-success", "Resource deleted"
end

test "should set flash alert on error" do
  @resource = create(:my_resource)
  
  sign_in @admin
  patch my_resource_url(@resource), params: { my_resource: { name: "" } }
  assert_response :unprocessable_content
  assert_select ".alert-danger"
end
```

## Testing Select Elements

```ruby
test "should display status options" do
  sign_in @admin
  get new_my_resource_url
  assert_response :success
  assert_select "select#my_resource_status"
  assert_select "option[value='active']", "Active"
  assert_select "option[value='inactive']", "Inactive"
end
```

## Testing Forms

```ruby
test "should display form with current values" do
  @resource = create(:my_resource)
  
  sign_in @admin
  get edit_my_resource_url(@resource)
  assert_response :success
  assert_select "input[value=#{@resource.name}]"
  assert_select "option[selected][value=#{@resource.status}]"
end

test "should submit form with valid params" do
  sign_in @admin
  post my_resources_url, params: {
    my_resource: attributes_for(:my_resource)
  }
  assert_redirected_to my_resource_url(MyResource.last)
end
```

## Testing Nested Resources

```ruby
test "should show parent resources" do
  @parent = create(:parent_resource)
  
  sign_in @admin
  get parent_resource_my_resources_url(@parent)
  assert_response :success
end

test "should create nested resource" do
  @parent = create(:parent_resource)
  
  sign_in @admin
  assert_difference("MyResource.count") do
    post parent_resource_my_resources_url(@parent), params: {
      my_resource: attributes_for(:my_resource)
    }
  end
end
```

## Testing Custom Actions

```ruby
test "should perform custom action" do
  @resource = create(:my_resource)
  
  sign_in @admin
  patch activate_my_resource_url(@resource)
  assert_redirected_to my_resource_url(@resource)
  @resource.reload
  assert @resource.active?
end
```

## Common Patterns

### Before Action Testing

If controller has `before_action :set_resource`, test the setup:

```ruby
test "should set resource when found" do
  @resource = create(:my_resource)
  
  sign_in @admin
  get my_resource_url(@resource)
  assert_response :success
  assert_select "h2", @resource.name
end

test "should redirect when resource not found" do
  sign_in @admin
  get my_resource_url(id: 99999)
  assert_redirected_to my_resources_url
end
```

### Testing with Multiple Records

```ruby
test "should show all records" do
  create_list(:my_resource, 5)
  
  sign_in @admin
  get my_resources_url
  assert_response :success
  
  # Count table rows (excluding header)
  assert_select "tbody tr", 5
end
```

## Factory Bot Helpers

### attributes_for

Get valid attributes without creating a record:

```ruby
test "should create resource" do
  sign_in @admin
  
  post my_resources_url, params: {
    my_resource: attributes_for(:my_resource)
  }
  
  assert_difference("MyResource.count", 1)
end
```

### build vs create

```ruby
# Returns unsaved instance
resource = build(:my_resource)
assert_not resource.persisted?

# Returns saved instance
resource = create(:my_resource)
assert resource.persisted?
```

### create_list

Create multiple records efficiently:

```ruby
test "should paginate results" do
  create_list(:my_resource, 25)
  
  sign_in @admin
  get my_resources_url, params: { page: 2 }
  assert_response :success
end
```

### Traits

```ruby
FactoryBot.define do
  factory :my_resource do
    status { :active }
    
    trait :inactive do
      status { :inactive }
    end
  end
end

# Usage
create(:my_resource, :inactive)
```

## Debugging Tips

### View Full Response

```ruby
test "debug test" do
  @resource = create(:my_resource)
  
  sign_in @admin
  get my_resource_url(@resource)
  puts response.body
  assert true
end
```

### Check Assigned Variables

```ruby
test "debug assigned variables" do
  @resource = create(:my_resource)
  
  sign_in @admin
  get my_resource_url(@resource)
  puts controller.instance_variable_get(:@resource).inspect
  assert true
end
```

## Best Practices

1. **Test one thing per test** - Keep tests focused and specific
2. **Use descriptive test names** - `should_create_resource_with_valid_params` not `test_1`
3. **Test both success and failure** - Every action should have positive and negative tests
4. **Use Factory Bot over fixtures** - More flexible and maintainable
5. **Test redirects properly** - Use `assert_redirected_to` not `follow_redirect!` unless needed
6. **Test flash messages** - They provide important user feedback
7. **Test authorization** - Both what users CAN and CANNOT do
8. **Test edge cases** - Empty results, not found, invalid params

## Common Pitfalls

### Wrong Authentication Method

```ruby
# WRONG - doesn't work
get my_resources_url, as: @admin

# CORRECT
sign_in @admin
get my_resources_url
```

### Wrong HTTP Method

```ruby
# WRONG
post edit_my_resource_url(@resource)

# CORRECT
patch my_resource_url(@resource)
```

### Missing Flash Assertion

```ruby
# INCOMPLETE
delete my_resource_url(@resource)
assert_redirected_to my_resources_url

# BETTER
delete my_resource_url(@resource)
assert_redirected_to my_resources_url
assert_not_nil flash[:notice]
```

### Wrong URL Helper

```ruby
# WRONG - collection helper for member action
delete my_resources_url(@resource)

# CORRECT
delete my_resource_url(@resource)
```
