# frozen_string_literal: true

# Because this is not really a production application that is going to be running on multiple servers
# It makes sense to do a sort of generate the secret key if it is missing.
# Much like how development ENV works
#
# This will have a few costs like for
# example session becoming invalid on new devices and you can share cookies between multiple servers
# However you can still use the ENV["SECRET_KEY_BASE"] and all this does not mater
key_file = Rails.root.join("storage/#{Rails.env}_secret.txt")
unless File.exist?(key_file)
  random_key = SecureRandom.hex(64)
  Rails.logger.warn "Secret key base not found, generating one at #{key_file}"
  FileUtils.mkdir_p(key_file.dirname)
  File.open(key_file, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
    file.write(random_key)
  end
end

Rails.application.config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") { File.binread(key_file) }
