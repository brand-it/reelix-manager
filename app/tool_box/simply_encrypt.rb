# frozen_string_literal: true

module SimplyEncrypt
  MODE = "AES-256-CBC"
  # `credentials.secret_key_base` is String|nil per RBS, but always present in production.
  # `.to_s` coerces nil to "" safely, `|| ""` satisfies the String constant type.
  KEY = Digest::SHA1.hexdigest(Rails.application.credentials.secret_key_base.to_s)[..31] || ""

  #: (String? data) -> [String?, String?]
  def encrypt(data)
    return [ nil, nil ] if data.blank?

    cipher = OpenSSL::Cipher.new(MODE)
    cipher.encrypt
    cipher.key = KEY
    vi = cipher.random_iv

    encrypted = cipher.update(data.to_s) + cipher.final
    [ encode(encrypted), encode(vi) ]
  end

  #: (String? data, String? iv) -> String?
  def decrypt(data, iv) # rubocop:disable Naming/MethodParameterName
    return if data.blank? || iv.blank?

    decipher = OpenSSL::Cipher.new(MODE)
    decipher.decrypt
    decipher.key = KEY
    decipher.iv = decode(iv)
    decipher.update(decode(data)) + decipher.final
  rescue StandardError => e
    Rails.logger.error e.message
    nil
  end

  private

  #: (String string) -> String
  def encode(string)
    CGI.escape(Base64.encode64(string))
  end

  #: (String string) -> String
  def decode(string)
    Base64.decode64(CGI.unescape(string))
  end
end
