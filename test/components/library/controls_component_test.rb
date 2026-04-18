# frozen_string_literal: true

require 'test_helper'

module Library
  class ControlsComponentTest < ViewComponent::TestCase
    test 'renders turbo stream search form with active media filter' do
      render_inline(Library::ControlsComponent.new(query: 'Breaking', media_type_filter: 'tv'))

      assert_selector "div[data-controller='submit-on-keyup']"
      assert_selector "form[data-turbo-stream='true']"
      assert_selector "input[type='search'][value='Breaking']"
      assert_selector "input[type='radio'][name='media_type'][value='tv'][checked='checked']", visible: false
      assert_selector "input[type='radio'][name='media_type'][value='tv'][data-action='change->submit-on-keyup#submit']",
                      visible: false
      assert_selector "label.btn[for='library_media_type_tv']", text: 'TV Shows'
    end
  end
end
