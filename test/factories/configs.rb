FactoryBot.define do
  factory :config_video, class: "Config::Video" do
    # Use /tmp which is guaranteed to exist in any environment
    transient do
      movie_dir { "/tmp" }
      tv_dir    { "/tmp" }
    end

    after(:build) do |config, evaluator|
      config.settings = {
        movie_path:    evaluator.movie_dir,
        tv_path:       evaluator.tv_dir,
        tmdb_api_key:  "test_key_123",
        processed_path: "/tmp"
      }
    end
  end
end
