# frozen_string_literal: true

module Sources
  # Batch-loads VideoBlobs by [media_type, tmdb_id] to avoid N+1 queries
  # when multiple movies or TV show results request their associated video blobs.
  class VideoBlobs < GraphQL::Dataloader::Source
    #: (::Array[[String, Integer]] keys) -> ::Array[::Array[::VideoBlob]]
    def fetch(keys)
      media_types = keys.map(&:first).uniq
      tmdb_ids    = keys.map(&:last).uniq
      grouped = ::VideoBlob.where(media_type: media_types, tmdb_id: tmdb_ids)
                           .group_by { |b| [b.media_type, b.tmdb_id] }
      keys.map { |key| grouped[key] || [] }
    end
  end
end
