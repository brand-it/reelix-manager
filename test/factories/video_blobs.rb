FactoryBot.define do
  factory :video_blob do
    sequence(:key) { |n| "/movies/Test Movie #{n} (2020)/Test Movie #{n} (2020).mkv" }
    sequence(:filename) { |n| "Test Movie #{n} (2020).mkv" }
    content_type { "video/x-matroska" }
    media_type   { :movie }
    title        { "Test Movie" }
    year         { 2020 }
    extra_type   { :feature_films }
    plex_version { false }
    optimized    { false }

    trait :tv do
      sequence(:key) { |n| "/tv/Test Show #{n} (2020)/Season 01/Test Show #{n} (2020) - S01E01.mkv" }
      sequence(:filename) { |n| "Test Show #{n} (2020) - S01E01.mkv" }
      media_type    { :tv }
      season_number { 1 }
      episode_number { 1 }
    end

    trait :with_tmdb_id do
      tmdb_id { 12_345 }
    end
  end
end
