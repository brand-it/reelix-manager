# frozen_string_literal: true

module TheMovieDb
  module Image
    IMAGE_BASE_URL = "https://image.tmdb.org/t/p"

    #: (String poster_path, ?size: String) -> String
    def self.poster_url(poster_path, size: "w342")
      "#{IMAGE_BASE_URL}/#{size}#{poster_path}"
    end
  end
end
