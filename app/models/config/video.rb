class Config::Video < Config
  setting do |s|
    s.attribute :movie_path
    s.attribute :tv_path
    s.attribute :tmdb_api_key, encrypted: true
    s.attribute :processed_path
  end

  validates :settings_movie_path, presence: true
  validates :settings_tv_path, presence: true
  validates :settings_tmdb_api_key, presence: true
  validates :settings_processed_path, presence: true

  validate :movie_path_must_exist, if: -> { settings_movie_path.present? }
  validate :tv_path_must_exist, if: -> { settings_tv_path.present? }
  validate :tmdb_api_key_must_be_valid, if: -> { settings_tmdb_api_key.present? }

  private

  #: () -> void
  def movie_path_must_exist
    unless Dir.exist?(settings_movie_path.to_s)
      errors.add(:settings_movie_path, "does not exist on the filesystem")
    end
  end

  #: () -> void
  def tv_path_must_exist
    unless Dir.exist?(settings_tv_path.to_s)
      errors.add(:settings_tv_path, "does not exist on the filesystem")
    end
  end

  #: () -> void
  def tmdb_api_key_must_be_valid
    unless TheMovieDb::Base.ping(api_key: settings_tmdb_api_key.to_s)
      errors.add(:settings_tmdb_api_key, "is invalid or the TMDB API could not be reached")
    end
  end
end
