# frozen_string_literal: true

module TheMovieDb
  class Base
    extend Dry::Initializer # steep:ignore UnknownConstant

    HOST = "api.themoviedb.org"
    VERSION = "3"
    CACHE_TTL = 7.days
    CACHE_NAMESPACE = "the_movie_db"

    # steep:ignore:start
    option :api_key, optional: true
    option :language, optional: true
    # steep:ignore:end

    class << self
      def option_names
        # steep:ignore:start
        @option_names ||= dry_initializer.options.map(&:target)
        # steep:ignore:end
      end

      def param_names
        # steep:ignore:start
        @param_names ||= dry_initializer.params.map(&:target)
        # steep:ignore:end
      end

      delegate :results, to: :new

      # Validates that the given API key can reach the TMDB API.
      # Returns true/false — safe to call from model validations.
      def ping(api_key:)
        new(api_key: api_key).ping
      rescue InvalidConfig
        false
      end
    end

    def results(use_cache: true, object_class: Hash)
      @results ||= {} # steep:ignore UnannotatedEmptyCollection
      key = [ use_cache, object_class ]
      @results[key] ||= use_cache ? cache_get(object_class:) : get(object_class:) # steep:ignore
    end

    def ping
      response = connection.get(ping_uri, { api_key: api_key })
      response.success?
    rescue StandardError
      false
    end

    private

    def ping_uri
      URI::HTTPS.build(host: HOST, path: "/#{VERSION}/authentication")
    end

    def cache_get(object_class: Hash)
      # Exclude the api_key from the cache key to avoid leaking secrets via cache key inspection.
      safe_params = query_params.except(:api_key, "api_key")
      Rails.cache.fetch(
        [ uri, safe_params, object_class ],
        namespace: CACHE_NAMESPACE,
        expires_in: CACHE_TTL,
        force: Rails.env.test?
      ) do
        get(object_class:)
      end
    end

    def get(object_class: Hash)
      response = connection.get(uri, query_params)
      return JSON.parse(response.body, object_class:) if response.success?

      raise Error, response
    end

    def connection
      # Only enable Faraday logging in local environments to avoid leaking the api_key
      # in query parameters into production logs.
      @connection ||= Faraday.new do |f|
        f.response :logger if Rails.env.local?
      end
    end

    def uri
      URI::HTTPS.build(host: HOST, path: [ "/#{VERSION}", path ].compact.join("/"))
    end

    def path
      self.class
          .name
          .split("::")[1..] # steep:ignore NoMethod
          &.join("::")
          &.parameterize(separator: "/") || ""
    end

    def query_params
      { api_key: }.tap do |hash|
        self.class.option_names.each do |name|
          hash[name] = send(name)
        end
      end.compact.with_indifferent_access
    end

    # Reads the API key from Config::Video; may be overridden by passing api_key: at instantiation.
    # Visit https://www.themoviedb.org/settings/api to obtain a key.
    def api_key
      # steep:ignore:start
      @api_key = super.presence || Config::Video.newest&.settings_tmdb_api_key.tap do |key|
        raise InvalidConfig, "TMDB API key is blank and is required" if key.blank?
      end
      # steep:ignore:end
    end

    # Pass an ISO 639-1 value to display translated data (e.g. "en-US").
    def language
      super || "en-US" # steep:ignore UnexpectedSuper
    end
  end
end
