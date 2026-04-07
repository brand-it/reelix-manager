# frozen_string_literal: true

# Mission Control – Jobs dashboard configuration.
#
# Uses the app's own Devise-based admin authentication instead of HTTP basic
# auth. The route is already gated behind `authenticate :user, ->(u) { u.admin? }`
# in routes.rb, so we only need to disable the built-in basic auth here.
Rails.application.configure do
  MissionControl::Jobs.http_basic_auth_enabled = false
end
