# frozen_string_literal: true

module Sources
  # Batch-loads VideoBlobs for TV episodes by [tmdb_id, season_number, episode_number].
  # Loads all blobs for the requested show IDs in a single query, then groups in memory.
  class EpisodeVideoBlobs < GraphQL::Dataloader::Source
    #: (::Array[[Integer?, Integer, Integer]] keys) -> ::Array[::Array[::VideoBlob]]
    def fetch(keys)
      tmdb_ids = keys.map(&:first).compact.uniq
      blobs = if tmdb_ids.empty?
                ::VideoBlob.none
              else
                ::VideoBlob.where(media_type: :tv, tmdb_id: tmdb_ids)
              end
      grouped = blobs.group_by { |b| [ b.tmdb_id, b.season_number, b.episode_number ] }
      keys.map do |key|
        key.first.nil? ? [] : (grouped[key] || [])
      end
    end
  end
end
