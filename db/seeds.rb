# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the Reelix client OAuth application (public client — no secret).
# This gives Reelix media clients a known client_id to use for the device flow.
Doorkeeper::Application.find_or_create_by!(uid: 'reelix-client') do |app|
  app.name          = 'Reelix'
  app.redirect_uri  = ''
  app.scopes        = 'all'
  app.confidential  = false
end

puts "Doorkeeper application 'Reelix' ready (client_id: reelix-client)"

# ---------------------------------------------------------------------------
# Development-only fake library data
# ---------------------------------------------------------------------------
if Rails.env.development?

  # ── Movies ────────────────────────────────────────────────────────────────
  seed_movies = [
    { title: 'Inception',               year: 2010, tmdb_id: 27_205,
      poster_url: 'https://image.tmdb.org/t/p/w342/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg' },
    { title: 'The Dark Knight',         year: 2008, tmdb_id: 155,
      poster_url: 'https://image.tmdb.org/t/p/w342/qJ2tW6WMUDux911r6m7haRef0WH.jpg' },
    { title: 'Interstellar',            year: 2014, tmdb_id: 157_336,
      poster_url: 'https://image.tmdb.org/t/p/w342/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg' },
    { title: 'The Matrix',              year: 1999, tmdb_id: 603,
      poster_url: 'https://image.tmdb.org/t/p/w342/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg' },
    { title: 'Pulp Fiction',            year: 1994, tmdb_id: 680,
      poster_url: 'https://image.tmdb.org/t/p/w342/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg' },
    { title: 'The Shawshank Redemption', year: 1994, tmdb_id: 278,
      poster_url: 'https://image.tmdb.org/t/p/w342/lyQBXzOQSuE59IsHyhrp0qIiPAz.jpg' },
    { title: 'Forrest Gump',            year: 1994, tmdb_id: 13,
      poster_url: 'https://image.tmdb.org/t/p/w342/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg' },
    { title: 'The Godfather',           year: 1972, tmdb_id: 238,
      poster_url: 'https://image.tmdb.org/t/p/w342/3bhkrj58Vtu7enYsLowi7GkAEWE.jpg' },
    { title: 'Fight Club',              year: 1999, tmdb_id: 550,
      poster_url: 'https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg' },
    { title: 'Goodfellas',              year: 1990, tmdb_id: 769,
      poster_url: 'https://image.tmdb.org/t/p/w342/aKuFiU82s5ISJpGZp7YkIr3kCUd.jpg' },
    { title: "Schindler's List",        year: 1993, tmdb_id: 424,
      poster_url: 'https://image.tmdb.org/t/p/w342/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg' },
    { title: 'The Silence of the Lambs', year: 1991, tmdb_id: 274,
      poster_url: 'https://image.tmdb.org/t/p/w342/uS9m8OBk1A8eM9I042bx8XXpqAq.jpg' },
    # Unmatched — no TMDB data yet (simulates blobs the matcher hasn't processed)
    { title: 'Some Obscure Film',       year: 2023, tmdb_id: nil,    poster_url: nil },
    { title: 'Another Unknown Movie',   year: 2022, tmdb_id: nil,    poster_url: nil },
    # Edge cases
    { title: nil, year: nil, tmdb_id: nil, poster_url: nil, filename_override: 'rip_disc_01_title_02.mkv' }
  ].freeze

  seed_movies.each do |attrs|
    title    = attrs[:title]
    year     = attrs[:year]
    filename = attrs.fetch(:filename_override) { "#{title} (#{year}).mkv" }
    key      = "/movies/#{title || 'Unknown'} (#{year || 'Unknown'})/#{filename}"

    VideoBlob.find_or_create_by!(key: key) do |b|
      b.filename    = filename
      b.title       = title
      b.year        = year
      b.tmdb_id     = attrs[:tmdb_id]
      b.poster_url  = attrs[:poster_url]
      b.media_type  = :movie
      b.extra_type  = :feature_films
      b.content_type = 'video/x-matroska'
    end
  end

  puts "Seeded #{seed_movies.size} movie blobs"

  # ── TV shows ──────────────────────────────────────────────────────────────
  seed_tv = [
    {
      title: 'Breaking Bad', year: 2008, tmdb_id: 1396,
      poster_url: 'https://image.tmdb.org/t/p/w342/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
      seasons: { 1 => 7, 2 => 6 }
    },
    {
      title: 'Game of Thrones', year: 2011, tmdb_id: 1399,
      poster_url: 'https://image.tmdb.org/t/p/w342/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
      seasons: { 1 => 6, 2 => 4 }
    },
    {
      title: 'The Office', year: 2005, tmdb_id: 2316,
      poster_url: 'https://image.tmdb.org/t/p/w342/7DJKHzAi83BmQrWLrYYOqcoKfhR.jpg',
      seasons: { 1 => 6, 2 => 6 }
    },
    # Unmatched show
    {
      title: 'Mystery Series', year: 2024, tmdb_id: nil,
      poster_url: nil,
      seasons: { 1 => 3 }
    }
  ].freeze

  seed_tv.each do |show|
    show[:seasons].each do |season_num, episode_count|
      (1..episode_count).each do |ep_num|
        filename = format("#{show[:title]} (#{show[:year]}) - S%02dE%02d.mkv", season_num, ep_num)
        key      = "/tv/#{show[:title]} (#{show[:year]})/Season %02d/#{filename}" % season_num

        VideoBlob.find_or_create_by!(key: key) do |b|
          b.filename      = filename
          b.title         = show[:title]
          b.year          = show[:year]
          b.tmdb_id       = show[:tmdb_id]
          b.poster_url    = show[:poster_url]
          b.media_type    = :tv
          b.extra_type    = :feature_films
          b.season_number  = season_num
          b.episode_number = ep_num
          b.content_type = 'video/x-matroska'
        end
      end
    end
  end

  episode_count = seed_tv.sum { |s| s[:seasons].values.sum }
  puts "Seeded #{episode_count} TV episode blobs (#{seed_tv.size} shows)"
end

# ---------------------------------------------------------------------------
# Error tracking sample data (development only)
# ---------------------------------------------------------------------------
if Rails.env.development?
  puts '', 'Seeding error tracking examples...'

  # Sample HTTP request error
  ErrorEntry.find_or_create_by!(fingerprint: 'http_error_001') do |e|
    e.error_class = 'ActiveRecord::RecordNotFound'
    e.error_message = "Couldn't find VideoBlob with 'id'=999"
    e.backtrace = "app/controllers/video_blobs_controller.rb:42:in `show'\napp/controllers/video_blobs_controller.rb:20:in `set_video_blob'\nlib/active_record/associations.rb:123:in `find'"
    e.status = :unacknowledged
    e.request_url = 'http://localhost:3000/video_blobs/999'
    e.request_method = 'GET'
    e.request_path = '/video_blobs/999'
    e.request_params = '{"id": "999"}'.to_json
    e.environment = 'development'
    e.created_at = 1.day.ago
  end

  # Sample job error
  ErrorEntry.find_or_create_by!(fingerprint: 'job_error_001') do |e|
    e.error_class = 'StandardError'
    e.error_message = 'Failed to process video blob: Invalid format'
    e.backtrace = "app/jobs/video_processing_job.rb:28:in `perform'\napp/jobs/video_processing_job.rb:15:in `process_video'\nlib/video_processor.rb:42:in `validate'"
    e.status = :acknowledged
    e.job_class = 'VideoProcessingJob'
    e.job_id = '12345'
    e.job_queue = 'default'
    e.job_arguments = '{"blob_id": 42}'.to_json
    e.environment = 'development'
    e.created_at = 3.days.ago
  end

  # Sample GraphQL error
  ErrorEntry.find_or_create_by!(fingerprint: 'graphql_error_001') do |e|
    e.error_class = 'ArgumentError'
    e.error_message = "unknown field 'invalidField'"
    e.backtrace = "app/graphql/types/query_type.rb:15:in `resolve'\nlib/graphql/schema.rb:456:in `execute'"
    e.status = :resolved
    e.request_path = '/graphql'
    e.request_params = '{"query": "{ videos { invalidField } }", "variables": {}}'.to_json
    e.environment = 'development'
    e.created_at = 7.days.ago
  end

  # Another HTTP error (similar to first one - same fingerprint group)
  ErrorEntry.find_or_create_by!(fingerprint: 'http_error_001') do |e|
    e.error_class = 'ActiveRecord::RecordNotFound'
    e.error_message = "Couldn't find VideoBlob with 'id'=888"
    e.backtrace = "app/controllers/video_blobs_controller.rb:42:in `show'\napp/controllers/video_blobs_controller.rb:20:in `set_video_blob'\nlib/active_record/associations.rb:123:in `find'"
    e.status = :unacknowledged
    e.request_url = 'http://localhost:3000/video_blobs/888'
    e.request_method = 'GET'
    e.request_path = '/video_blobs/888'
    e.request_params = '{"id": "888"}'.to_json
    e.environment = 'development'
    e.created_at = 2.hours.ago
  end

  # Old error (for cleanup testing)
  ErrorEntry.find_or_create_by!(fingerprint: 'old_error_001') do |e|
    e.error_class = 'RuntimeError'
    e.error_message = 'Deprecated feature accessed'
    e.backtrace = "app/controllers/legacy_controller.rb:10:in `index'"
    e.status = :resolved
    e.request_path = '/legacy/feature'
    e.environment = 'development'
    e.created_at = 45.days.ago
  end

  puts "Seeded #{ErrorEntry.count} error entries"
  puts "  - Unacknowledged: #{ErrorEntry.unacknowledged.count}"
  puts "  - Acknowledged: #{ErrorEntry.acknowledged.count}"
  puts "  - Resolved: #{ErrorEntry.resolved.count}"
end
