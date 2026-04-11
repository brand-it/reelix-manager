---
applyTo: "**"
---

# Media Upload Path System

This document describes how uploaded media files are named, placed on disk, and
recorded in the database. Follow these rules whenever writing code that handles
file uploads or reads the resulting paths.

---

## End-to-End Flow

```
1. Client  → POST /files               tus starts the upload, returns an upload UID
2. Client  → PATCH /files/:uid         tus receives chunks; stored in tmp/tus_uploads/:uid
3. Client  → FinalizeUpload mutation   with upload_id, tmdb_id, media_type (+ season/episode for TV)

Server-side (FinalizeUpload):
  a. Validate the tus upload is 100 % complete.
  b. Validate required arguments (TV needs season_number + episode_number).
  c. Create an unsaved VideoBlob with tmdb_id, media_type, season/episode, and path_extension.
  d. Fetch title, year, poster, and (TV) episode title from TMDB into that blob.
  e. Ask the blob for its generated filename and absolute media_path.
  f. Move file: tmp/tus_uploads/:uid → tmp/media_staging/:uuid.:ext   (staging)
  g. Delete tus metadata.
  h. mkdir_p the final directory.
  i. Move file: tmp/media_staging/:uuid.:ext → <final destination>
  j. find_or_initialize VideoBlob by key (= media_path), populate fields, save.
  k. Return { video_blob, destination_path, errors }.
```

### Why staging?

The staging area (`tmp/media_staging/`) holds a complete, byte-perfect file that
has not yet been committed to the media library. If the TMDB fetch or path-building
step fails (steps c-e), the file stays in `tmp/tus_uploads/` so the caller can
retry the mutation with the same upload UID. If a failure occurs after the staging
move (steps h-j), the file is in staging but not in the media library — a future
cleanup job can sweep `tmp/media_staging/` for orphaned files.

---

## Path Construction

Paths are built directly from `VideoBlob`.

During upload finalization the app creates an **unsaved blob**, populates it with
TMDB metadata, then asks the blob for:

- `generated_filename` — the final basename
- `directory` — the absolute destination directory
- `media_path` — the final absolute path

`VideoBlob` also reads `Config::Video.newest` internally for the movie/TV roots,
so callers should not pass `movie_path` / `tv_path` through the upload pipeline.

Names are sanitized before they are used in paths:

- `/` and `\` become `-`
- repeated dots are collapsed to a single `.`
- null bytes are removed
- surrounding whitespace is stripped

### Movie

```
{movie_path}/{Title (Year)}/
  {Title (Year)}.ext
```

**Example** — Batman Begins (TMDB id 272), uploaded as an MKV:

```
/media/movies/Batman Begins (2005)/
  Batman Begins (2005).mkv
```

**Source fields:**
| Field            | Source |
|------------------|--------|
| title            | TMDB `title` |
| year             | `release_date[0..3]` (first 4 chars → integer) |
| tmdb_id          | mutation argument |
| path_extension   | tus metadata filename extension (or `mkv` fallback) |
| settings_movie_path | `Config::Video.newest.settings_movie_path` |

### TV Episode

```
{tv_path}/{Show (Year)}/Season XX/
  {Show (Year)} - sXXeYY - Episode Title.ext
```

Season and episode numbers are **zero-padded to two digits**.

When the episode title is unavailable the trailing ` - Episode Title` portion is
**omitted** (not replaced with a placeholder):

```
{Show (Year)} - sXXeYY.ext
```

**Example** — Breaking Bad Season 1 Episode 1 (TMDB id 1396):

```
/media/tv/Breaking Bad (2008)/Season 01/
  Breaking Bad (2008) - s01e01 - Pilot.mkv
```

**Source fields:**
| Field             | Source |
|-------------------|--------|
| title             | TMDB `name` |
| year              | `first_air_date[0..3]` (integer) |
| tmdb_id           | mutation argument |
| season_number     | mutation argument |
| episode_number    | mutation argument |
| episode_title     | `/tv/:id/season/:n` → `episodes[].find{episode_number}.name` |
| path_extension    | tus metadata filename extension (or `mkv` fallback) |
| settings_tv_path  | `Config::Video.newest.settings_tv_path` |

---

## VideoBlob Fields Populated After Finalize

| Field            | Source |
|------------------|--------|
| `key`            | Full absolute path (`VideoBlob#media_path`) |
| `filename`       | Final basename (`VideoBlob#generated_filename`) |
| `title`          | TMDB title / name |
| `year`           | Parsed from TMDB release_date / first_air_date |
| `tmdb_id`        | Argument |
| `media_type`     | Argument (`"movie"` or `"tv"`) |
| `season_number`  | Argument (TV only) |
| `episode_number` | Argument (TV only) |
| `path_extension` | Upload filename extension |
| `episode_title`  | TMDB season lookup result for TV uploads |
| `content_type`   | Derived from extension via `KeyParserService::VIDEO_MIME_TYPES` |
| `poster_url`     | `https://image.tmdb.org/t/p/w500{poster_path}` |

Deduplication uses `find_or_initialize_by(key:)` — re-finalizing the same path
updates the existing record rather than creating a duplicate.

---

## VideoBlob Helper Methods

`VideoBlob#media_name` — computes the canonical display name from stored fields
(no path components, no extension).

```ruby
blob.media_name  # "Batman Begins (2005)"
                 # "Breaking Bad (2008) - s01e01"
```

`VideoBlob#generated_filename` — computes the final filename from the blob's
stored metadata.

```ruby
blob.generated_filename  # "Batman Begins (2005).mkv"
                         # "Breaking Bad (2008) - s01e01 - Pilot.mkv"
```

`VideoBlob#directory` — computes the absolute destination directory.

```ruby
blob.directory  # "/media/movies/Batman Begins (2005)"
                # "/media/tv/Breaking Bad (2008)/Season 01"
```

`VideoBlob#media_path` — computes the final absolute path.

```ruby
blob.media_path  # "/media/movies/Batman Begins (2005)/Batman Begins (2005).mkv"
                 # "/media/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - s01e01 - Pilot.mkv"
```

All three methods return `nil` when required fields are missing.

---

## Edge Cases

| Situation                              | Behaviour                                                   |
|----------------------------------------|-------------------------------------------------------------|
| Year missing from TMDB                 | Year omitted from name: `Title`                            |
| Episode title not in TMDB season data  | Episode title segment omitted from filename                 |
| Duplicate key (file already exists)    | `VideoBlob` record is updated in place; file is overwritten |
| Config::Video not set up               | Mutation returns an error; tus file untouched               |
| TMDB fetch fails                       | Mutation returns an error; tus file untouched, retry with same UID |
| Unknown file extension                 | `content_type` stored as nil; path uses the detected extension |

---

## Required Config

Both base paths must be set in `Config::Video` before any upload can be finalized:

- `settings_movie_path` — absolute path to the movie library root
- `settings_tv_path` — absolute path to the TV library root
- `settings_tmdb_api_key` — API key for TMDB lookups
