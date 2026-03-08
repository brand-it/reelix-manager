class Config::Video < Config
  setting do |s|
    s.attribute :movie_path
    s.attribute :tv_path
    s.attribute :tmdb_api_key
    s.attribute :processed_path
  end

  validates :settings_movie_path, presence: true
  validates :settings_tv_path, presence: true
  validates :settings_tmdb_api_key, presence: true
  validates :settings_processed_path, presence: true

  validate :movie_path_must_exist, if: -> { settings_movie_path.present? }
  validate :tv_path_must_exist, if: -> { settings_tv_path.present? }

  private

  def movie_path_must_exist
    unless Dir.exist?(settings_movie_path)
      errors.add(:settings_movie_path, "does not exist on the filesystem")
    end
  end

  def tv_path_must_exist
    unless Dir.exist?(settings_tv_path)
      errors.add(:settings_tv_path, "does not exist on the filesystem")
    end
  end
end
