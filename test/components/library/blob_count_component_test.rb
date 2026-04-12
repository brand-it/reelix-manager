require "test_helper"

class Library::BlobCountComponentTest < ViewComponent::TestCase
  test "renders plural count" do
    render_inline(Library::BlobCountComponent.new(count: 2))

    assert_text "2 videos"
  end

  test "renders singular count" do
    render_inline(Library::BlobCountComponent.new(count: 1))

    assert_text "1 video"
  end

  test "when there are zero videos" do
    render_inline(Library::BlobCountComponent.new(count: 0))

    assert_text "0 videos"
  end
end
