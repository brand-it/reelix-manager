# frozen_string_literal: true

require 'test_helper'

module Library
  class ResultsComponentTest < ViewComponent::TestCase
    test 'renders empty state with query' do
      render_inline(Library::ResultsComponent.new(video_blobs: [], query: 'Missing'))

      assert_text 'No blobs found for “Missing”.'
    end

    test 'renders blob cards' do
      render_inline(Library::ResultsComponent.new(video_blobs: [video_blobs(:inception)], query: ''))

      assert_text 'Inception'
      assert_selector '.card-title', text: 'Inception'
    end
  end
end
