// Adds an album to the shared catalog from its MusicBrainz ID and copies
// its cover once (docs/features/search.md). Storage and database access are
// passed in, so this runs in tests without Supabase.

import { Image, ReleaseGroup } from "./musicbrainz.ts";

export interface Album {
  id: string;
  musicbrainz_id: string;
  title: string;
  artist: string;
  year: number | null;
  cover_url: string | null;
}

export interface Deps {
  findAlbum(musicbrainzId: string): Promise<Album | null>;
  releaseGroup(musicbrainzId: string): Promise<ReleaseGroup>;
  /** Inserts the album; returns null when another request added it first. */
  insertAlbum(group: ReleaseGroup): Promise<Album | null>;
  cover(musicbrainzId: string): Promise<Image | null>;
  /** Stores the image and returns its public URL. */
  storeCover(albumId: string, image: Image): Promise<string>;
  setCoverUrl(albumId: string, url: string): Promise<void>;
}

export class BadRequest extends Error {}

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function addAlbum(
  musicbrainzId: string,
  deps: Deps,
): Promise<Album> {
  if (!uuid.test(musicbrainzId)) throw new BadRequest("not a MusicBrainz ID");
  let album = await deps.findAlbum(musicbrainzId);
  if (!album) {
    const group = await deps.releaseGroup(musicbrainzId);
    album = await deps.insertAlbum(group) ??
      await deps.findAlbum(musicbrainzId);
    if (!album) throw new Error("album vanished after insert");
  }
  // Also retried for albums whose cover failed before.
  if (!album.cover_url) {
    const image = await deps.cover(musicbrainzId);
    if (image) {
      const url = await deps.storeCover(album.id, image);
      await deps.setCoverUrl(album.id, url);
      album = { ...album, cover_url: url };
    }
  }
  return album;
}
