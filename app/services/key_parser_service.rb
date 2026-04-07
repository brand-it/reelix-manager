# frozen_string_literal: true

# Converts a file path into structured metadata by matching it against the
# naming conventions used by Plex (and compatible media managers).
#
# Usage:
#   result = KeyParserService.call("/movies/Inception (2010)/Inception (2010).mkv")
#   result.movie?   # => true
#   result.title    # => "Inception"
#   result.year     # => 2010
class KeyParserService
  VIDEO_FORMATS = %w[
    .avi .mp4 .mkv .mov .wmv .flv .webm .mpeg .mpg .3gp .m4v .swf .rm .vob
    .ogv .ts .f4v .divx .asf .mts .m2ts .dv .mxf .f4p .gxf .m2v .yuv .amv
    .svi .nsv
  ].freeze

  VIDEO_MIME_TYPES = {
    "avi"  => "video/x-msvideo",
    "mp4"  => "video/mp4",
    "mkv"  => "video/x-matroska",
    "mov"  => "video/quicktime",
    "wmv"  => "video/x-ms-wmv",
    "flv"  => "video/x-flv",
    "webm" => "video/webm",
    "mpeg" => "video/mpeg",
    "mpg"  => "video/mpeg",
    "3gp"  => "video/3gpp",
    "m4v"  => "video/x-m4v",
    "swf"  => "application/x-shockwave-flash",
    "rm"   => "application/vnd.rn-realmedia",
    "vob"  => "video/dvd",
    "ogv"  => "video/ogg",
    "ts"   => "video/mp2t",
    "f4v"  => "video/mp4",
    "divx" => "video/divx",
    "asf"  => "video/x-ms-asf",
    "mts"  => "model/vnd.mts",
    "m2ts" => "video/mp2t",
    "dv"   => "video/x-dv",
    "mxf"  => "application/mxf",
    "f4p"  => "video/mp4",
    "gxf"  => "application/gxf",
    "m2v"  => "video/mpeg",
    "yuv"  => "application/octet-stream",
    "amv"  => "video/x-amv",
    "svi"  => "video/vnd.sealedmedia.softseal.mov",
    "nsv"  => "video/x-nsv"
  }.freeze

  EXTRA_DIR_NAMES = VideoBlob::EXTRA_TYPES.map { |_k, v| v[:dir_name] }.freeze
  PLEX_VERSIONS   = "Plex Versions"
  OPTIMIZED       = "Optimized for"

  BlobData = Data.define(
    :content_type,
    :edition,
    :episode_last,
    :episode,
    :extra_number,
    :extra_type,
    :extra,
    :filename,
    :optimized,
    :part,
    :plex_version,
    :season,
    :title,
    :type,
    :year
  )

  class BlobData
    #: () -> bool
    def movie? = type == "Movie"

    #: () -> bool
    def tv? = type == "Tv"
  end

  # Helper regex fragments
  SPACE_OR_NOTHING = /(?:\s+|)/
  TITLE_MATCHER    = /(?<title>.*)/
  EDITION          = /\{edition-(?<edition>.*)\}/

  MATCHER_WITH_YEAR_EDITION = /#{TITLE_MATCHER}[(](?<year>\d{4})[)]#{SPACE_OR_NOTHING}#{EDITION}/
  MATCHER_WITH_YEAR         = /#{TITLE_MATCHER}[(](?<year>\d{4})[)]/

  VIDEO_FORMAT_UNION = Regexp.union(VIDEO_FORMATS)

  TV_SHOW_SEASON_EPISODE      = /[sS](?<season>\d+)[eE](?<episode>\d+)/
  TV_SHOW_SEASON_EPISODE_LAST = /[sS](?<season>\d+)[eE](?<episode>\d+)-[eE](?<episode_last>\d+)/

  TV_SHOW_MATCHER_FULL     = /#{MATCHER_WITH_YEAR}.*-#{SPACE_OR_NOTHING}#{TV_SHOW_SEASON_EPISODE}#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<date>.*)#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<episode_name>.*).*#{VIDEO_FORMAT_UNION}/
  TV_SHOW_WITHOUT_EP_NAME  = /#{MATCHER_WITH_YEAR}.*-#{SPACE_OR_NOTHING}#{TV_SHOW_SEASON_EPISODE}#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<date>.*).*#{VIDEO_FORMAT_UNION}/
  TV_SHOW_WITHOUT_DATE     = /#{MATCHER_WITH_YEAR}.*-#{SPACE_OR_NOTHING}#{TV_SHOW_SEASON_EPISODE}#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<episode_name>.*).*#{VIDEO_FORMAT_UNION}/
  TV_SHOW_WITHOUT_NUMBER   = /#{MATCHER_WITH_YEAR}.*-#{SPACE_OR_NOTHING}(?<date>.*)#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<episode_name>.*).*#{VIDEO_FORMAT_UNION}/
  TV_SHOW_WITHOUT_YEAR     = /#{TITLE_MATCHER}.*-#{SPACE_OR_NOTHING}#{TV_SHOW_SEASON_EPISODE}#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<date>.*)#{SPACE_OR_NOTHING}-#{SPACE_OR_NOTHING}(?<episode_name>.*).*#{VIDEO_FORMAT_UNION}/
  TV_SHOW_NUMBER_ONLY      = /#{TV_SHOW_SEASON_EPISODE}\.*#{VIDEO_FORMAT_UNION}/

  class << self
    #: (String key, ?movie_path: String?, ?tv_path: String?) -> BlobData?
    def call(key, movie_path: nil, tv_path: nil)
      new(key, movie_path:, tv_path:).call
    end
  end

  # @rbs @key: String
  # @rbs @movie_path: String?
  # @rbs @tv_path: String?
  # @rbs @simplified_key: String
  # @rbs @directory_name: String
  # @rbs @filename: String

  #: (String key, ?movie_path: String?, ?tv_path: String?) -> void
  def initialize(key, movie_path: nil, tv_path: nil)
    @key        = key.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace).strip
    @movie_path = movie_path || Config::Video.newest&.settings_movie_path
    @tv_path    = tv_path    || Config::Video.newest&.settings_tv_path
  end

  #: () -> BlobData?
  def call
    return unless video_file?
    return parsed_movie   if key_movie?
    parsed_tv_show if key_tv_show?
  end

  private

  attr_reader :key, :movie_path, :tv_path

  #: () -> bool
  def video_file?
    VIDEO_FORMATS.any? { |ext| key.end_with?(ext) }
  end

  #: () -> bool
  def key_movie?
    movie_path.present? && key.start_with?(movie_path)
  end

  #: () -> bool
  def key_tv_show?
    tv_path.present? && key.start_with?(tv_path)
  end

  #: () -> BlobData
  def parsed_movie
    match = (
      filename.match(MATCHER_WITH_YEAR_EDITION) ||
      filename.match(MATCHER_WITH_YEAR) ||
      filename.match(TITLE_MATCHER)
    )&.named_captures || {}

    dir_match = (
      directory_name.match(MATCHER_WITH_YEAR_EDITION) ||
      directory_name.match(MATCHER_WITH_YEAR) ||
      directory_name.match(TITLE_MATCHER)
    )&.named_captures || {}

    BlobData.new(
      content_type:  content_type,
      edition:       (dir_match["edition"].presence || match["edition"])&.strip,
      episode:       nil,
      episode_last:  nil,
      extra_number:  extra_number,
      extra_type:    extra_type_key,
      extra:         extra,
      filename:      filename,
      optimized:     optimized?,
      part:          part,
      plex_version:  plex_version?,
      season:        nil,
      title:         coerce_title(dir_match["title"].presence || match["title"]),
      type:          "Movie",
      year:          (dir_match["year"].presence || match["year"])&.to_i
    )
  end

  #: () -> BlobData
  def parsed_tv_show
    match = (
      filename.match(TV_SHOW_WITHOUT_DATE) ||
      filename.match(TV_SHOW_MATCHER_FULL) ||
      filename.match(TV_SHOW_WITHOUT_EP_NAME) ||
      filename.match(TV_SHOW_WITHOUT_NUMBER) ||
      filename.match(TV_SHOW_WITHOUT_YEAR) ||
      filename.match(TV_SHOW_NUMBER_ONLY)
    )&.named_captures || {}

    dir_match = (
      directory_name.match(MATCHER_WITH_YEAR) ||
      directory_name.match(TITLE_MATCHER)
    )&.named_captures || {}

    BlobData.new(
      content_type:  content_type,
      edition:       nil,
      episode:       match["episode"]&.to_i,
      episode_last:  episode_last,
      extra_number:  nil,
      extra_type:    :feature_films,
      extra:         nil,
      filename:      filename,
      optimized:     optimized?,
      part:          part,
      plex_version:  plex_version?,
      season:        match["season"]&.to_i,
      title:         coerce_title(dir_match["title"].presence || match["title"]),
      type:          "Tv",
      year:          (dir_match["year"].presence || match["year"])&.to_i
    )
  end

  #: () -> String
  def simplified_key
    @simplified_key ||= begin
      base = key_movie? ? movie_path : tv_path
      key.delete_prefix(base.to_s).split("/").compact_blank.join("/")
    end
  end

  #: () -> String
  def directory_name
    @directory_name ||= begin
      paths = simplified_key.split("/")
      return "" if paths.size <= 1

      simplified_key.split("/").first.to_s.strip
    end
  end

  #: () -> String
  def filename
    @filename ||= key.split("/").last.to_s.strip
  end

  #: () -> String?
  def extra
    (simplified_key.delete_prefix("#{directory_name}/").split("/") & EXTRA_DIR_NAMES).first
  end

  #: () -> Integer?
  def extra_number
    (filename.match(/#(\d+)/) || [])[1]&.to_i
  end

  #: () -> Symbol
  def extra_type_key
    found = VideoBlob::EXTRA_TYPES.find { |_k, v| extra&.include?(v[:dir_name]) }
    found ? found.first.to_sym : :feature_films
  end

  #: () -> bool
  def plex_version?
    simplified_key.delete_prefix("#{directory_name}/").include?(PLEX_VERSIONS)
  end

  #: () -> String?
  def content_type
    ext = filename.split(".").last
    VIDEO_MIME_TYPES[ext]
  end

  #: () -> bool
  def optimized?
    plex_version? && simplified_key.delete_prefix("#{directory_name}/").include?(OPTIMIZED)
  end

  #: () -> Integer?
  def part
    (filename.match(/\spart(\d+)/i) || filename.match(/\spt(\d+)/i) || [])[1]&.to_i
  end

  #: () -> Integer?
  def episode_last
    (filename.match(TV_SHOW_SEASON_EPISODE_LAST)&.named_captures || {})["episode_last"]&.to_i
  end

  #: (String? raw) -> String?
  def coerce_title(raw)
    return nil if raw.blank?

    raw.strip.gsub(/ {2,}/, " ").gsub(/ (-\w)/, '\1')
  end
end
