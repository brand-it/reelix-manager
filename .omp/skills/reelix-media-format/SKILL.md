---
id: reelix-media-format
description: Canonical file and folder naming for movies and TV shows in the Reelix media library. Use this whenever creating, renaming, moving, or scanning media files, or when implementing or testing path construction (VideoBlob, KeyParserService, uploads, library scanner).
---

This is the official on-disk format for the Reelix media library. Every media file — whether it arrived through a tus upload or was discovered by a library scan — must conform to it. The format descends from classic media-server layout conventions, but this document is authoritative for Reelix; where the layout has diverged, the divergence wins.

## Library layout

Keep content types in separate root directories. Roots come from `Config::Video` (`settings_movie_path`, `settings_tv_path`):

```
{movie_path}/
  Batman Begins (2005)/
    Batman Begins (2005).mkv
{tv_path}/
  Breaking Bad (2008)/
    Season 01/
      Breaking Bad (2008) - s01e01 - Pilot.mkv
```

`.ext` is a placeholder — use the real extension (`.mkv`, `.mp4`, `.m4v`, `.avi`, ...).

## Movies

### One folder per movie (recommended)

```
{movie_path}/
  Batman Begins (2005)/
    Batman Begins (2005).mkv
    Batman Begins (2005).en.srt
    poster.jpg
```

Folder name equals the file base name: `{Title} ({Year})`. External assets (posters, subtitles) live next to the video in the same folder.

### Stand-alone files

A file without its own folder is allowed and must still be named `{Title} ({Year}).ext`:

```
{movie_path}/
  Avatar (2009).mkv
  Blade Runner (1982).mp4
```

### Editions

A specific cut of a movie (Director's Cut, Extended, Unrated, ...) is marked with an edition tag in curly braces: `{edition-Edition Name}`. The edition name is free text, max 32 characters, sanitized on write (slashes, backslashes, repeated dots, nulls, surrounding whitespace).

**Canonical placement: the tag goes in the filename only; the folder stays plain.** All editions of a film share the movie's folder, which keeps them discoverable as one title:

```
{movie_path}/
  Blade Runner (1982)/
    Blade Runner (1982).mp4
    Blade Runner (1982) {edition-Director's Cut}.mp4
    Blade Runner (1982) {edition-Final Cut}.mkv
```

- No edition → no tag. The tag is omitted entirely, never replaced by a placeholder.
- The scanner accepts the tag in the folder too, but uploads must not emit it there.
- Dedup is by absolute path (`VideoBlob#key`), so each edition is its own record under the same `tmdb_id`.

### Split movies

A movie spanning multiple files uses `-ptN` part suffixes in the filename (and the corresponding part on the `VideoBlob#part` column):

```
{movie_path}/
  The Lord of the Rings (2001)/
    The Lord of the Rings (2001)-pt1.mkv
    The Lord of the Rings (2001)-pt2.mkv
```

Parts of the same file share the movie folder and are ordered by `part`. Single-file movies never carry a part suffix. Edition + part compose with the edition tag first: `Kill Bill (2003) {edition-Uncut}-pt1.mkv`.

## TV shows

### Episodes

```
{tv_path}/
  Breaking Bad (2008)/
    Season 01/
      Breaking Bad (2008) - s01e01 - Pilot.mkv
```

- Episode file: `{Show} ({Year}) - s{XX}e{YY} - {Episode Title}.ext`
- Season folders are `Season XX`, zero-padded to two digits; season and episode numbers in `sXXeYY` are zero-papped too
- When the episode title is unavailable, the trailing ` - {Episode Title}` is omitted: `Breaking Bad (2008) - s01e01.mkv`
- Multi-part episodes take the same `-ptN` suffix as movies: `Show (Year) - s01e01 - Title-pt1.mkv`

### Show extras

Show-level extras go in dedicated subfolders directly under the show directory:

```
{tv_path}/
  Game of Thrones (2011)/
    Season 01/
    Trailers/
      Trailer 1.mkv
    Featurettes/
      Special Effects.mkv
```

Recognized extra types: `Behind The Scenes`, `Deleted Scenes`, `Featurettes`, `Interviews`, `Scenes`, `Shorts`, `Trailers`, `Other`.

### Inline episode extras

An episode's extras sit next to the episode file with a suffix, hyphen and word glued together: `S01E01 - Episode Title-{type}.ext` where `{type}` is one of `behindthescenes`, `deleted`, `featurette`, `interview`, `scene`, `short`, `trailer`, `other` (optionally numbered: `-deleted1`, `-deleted2`).

## Naming rules

- Titles are sanitized before use in paths: `/` and `\` become `-`, repeated dots collapse to one, null bytes are removed, surrounding whitespace is stripped.
- The year is 4 digits in parentheses: `(2005)`. When a title has no release year, the year segment is omitted (`Title.ext`), it is not blanked or guessed.
- The display name (no extension, no path) is `Title (Year)` for movies and `Title (Year) - sXXeYY` for episodes — `VideoBlob#media_name`.
- Uppercase extensions in the wild are normalized to lowercase when stored (`path_extension`), but on-disk names keep whatever case the source used.

## Edge cases

| Situation | Behavior |
|---|---|
| No year in metadata | Year segment omitted: `Title.ext` |
| Episode title unknown | Title segment omitted: `Show (Year) - s01e01.ext` |
| Same file uploaded again | Same key → existing `VideoBlob` updated in place, file overwritten |
| Edition on a TV episode | Ignored — edition is a movie concept only |
| `part` on a single file | Omitted — `part` only renders for multi-part media |

## How Reelix consumes this format

- **Uploads**: `finalizeUpload` (with `edition`/`part` for movies) → `VideoBlob#media_path` / `#generated_filename` build the path above; `KeyParserService::VIDEO_MIME_TYPES` maps the extension to `content_type`.
- **Scans**: `LibraryScanJob` → `KeyParserService` parses an existing path back into title/year/edition/part/season/episode/extra_type using the same shapes. Known scanner gap: `part` is only recognized in the space form (`... pt1` / `... part1`); the canonical hyphenated `-pt1` suffix produced by uploads is not yet parsed back, so a scanned split file can end up with `part = nil`.
- **Dedup**: `VideoBlob#key` (absolute path) is unique; `find_or_initialize_by(key:)` is the upsert point.

When in doubt, match an existing file in the library: folder = `Title (Year)` (TV: `Show (Year)/Season XX`), filename = the most precise identifier you have.
