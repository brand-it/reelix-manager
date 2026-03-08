class Config::Video < Config
  setting do |s|
    s.attribute :upload_path
    s.attribute :tmdb_api_key
    s.attribute :processed_path
  end

  validates :settings_upload_path, presence: true
  validates :settings_tmdb_api_key, presence: true
  validates :settings_processed_path, presence: true
end
