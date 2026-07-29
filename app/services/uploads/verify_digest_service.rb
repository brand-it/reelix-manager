# frozen_string_literal: true

module Uploads
  class VerifyDigestService < ApplicationService
    class DigestMismatchError < StandardError
      #: (String client_digest, String server_digest) -> void
      def initialize(client_digest, server_digest)
        @client_digest = client_digest
        @server_digest = server_digest
        super('Upload digest mismatch: file may be corrupted. ' \
              "Client: #{client_digest[0..15]}... Server: #{server_digest[0..15]}...")
      end
    end

    class << self
      #: (file_path: String, client_digest: String) -> String
      def call(file_path:, client_digest:)
        new(file_path:, client_digest:).call
      end
    end

    # @rbs @file_path: String
    # @rbs @client_digest: String

    #: (file_path: String, client_digest: String) -> void
    def initialize(file_path:, client_digest:)
      super()
      @file_path = file_path
      @client_digest = client_digest
    end

    #: () -> String
    def call
      server_digest = compute_digest

      raise DigestMismatchError.new(@client_digest, server_digest) unless constant_time_compare(server_digest, @client_digest)

      server_digest
    end

    private

    #: () -> String
    def compute_digest
      digest = Digest::SHA256.new
      File.open(@file_path, 'rb') do |f|
        # Read in 1 MB chunks to avoid loading the entire file into memory
        while (chunk = f.read(1024 * 1024))
          digest.update(chunk)
        end
      end
      Base64.strict_encode64(digest.digest)
    end

    #: (String expected, String actual) -> bool
    def constant_time_compare(expected, actual)
      ActiveSupport::SecurityUtils.secure_compare(expected, actual)
    end
  end
end
