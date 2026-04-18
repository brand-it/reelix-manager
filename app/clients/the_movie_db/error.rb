# frozen_string_literal: true

module TheMovieDb
  class Error < StandardError
    attr_reader :object, :body

    #: (Faraday::Response object) -> void
    def initialize(object)
      @object = object #: Faraday::Response
      @body = parse_body(object.body) #: ::Hash[String, untyped] | String?
      super(build_message(object))
    end

    private

    #: (String? raw_body) -> (::Hash[String, untyped] | String?)
    def parse_body(raw_body)
      JSON.parse(raw_body.to_s)
    rescue JSON::ParserError, TypeError
      raw_body
    end

    #: (Faraday::Response object) -> String
    def build_message(object)
      status = object.respond_to?(:status) ? object.status : nil
      url    = object.env.respond_to?(:url) ? object.env.url : nil

      path =
        if url.respond_to?(:path)
          url.path # steep:ignore NoMethod
        elsif url
          url.to_s.split('?', 2).first
        end

      message = +'TheMovieDb API error'
      message << " (status #{status})" if status
      message << " for #{path}" if path && !path.empty?
      message
    end
  end
end
