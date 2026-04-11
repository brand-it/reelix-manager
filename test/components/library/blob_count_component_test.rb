require "test_helper"

class Library::BlobCountComponentTest < ViewComponent::TestCase
  test "renders plural count" do
    render_inline(Library::BlobCountComponent.new(count: 2))

    assert_text "2 blobs"
  end

  test "renders singular count" do
    render_inline(Library::BlobCountComponent.new(count: 1))

    assert_text "1 blob"
  end
end
