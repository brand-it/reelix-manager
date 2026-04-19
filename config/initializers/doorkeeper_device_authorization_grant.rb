# frozen_string_literal: true

Doorkeeper::DeviceAuthorizationGrant.configure do
  # Minimum polling interval (seconds) clients must wait between poll attempts.
  device_code_polling_interval 5

  # How long (seconds) a device code is valid before it expires. 15 minutes.
  device_code_expires_in 900

  # URL the user visits in their browser to approve the device.
  verification_uri lambda { |host_name|
    "#{host_name}/oauth/device"
  }

  # Convenience URL that pre-fills the user_code in the form (optional).
  verification_uri_complete lambda { |verification_uri, _host_name, device_grant|
    "#{verification_uri}?user_code=#{CGI.escape(device_grant.user_code)}"
  }
end
