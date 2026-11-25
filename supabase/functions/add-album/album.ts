// Adds an album to the shared catalog from its MusicBrainz ID and copies
// its cover once (docs/features/search.md). Storage and database access are
// passed in, so this runs in tests without Supabase.

import { Image, ReleaseGroup } from "./musicbrainz.ts";

export interface Album {
  id: string;
  /** Null for albums added by hand. */
  musicbrainz_id: string | null;
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

/** An album added by hand (no MusicBrainz ID), with an optional photo. */
export interface ManualAlbum {
  title: string;
  artist: string;
  year: number | null;
  cover: Image | null;
}

export interface ManualDeps {
  insertManual(
    album: Omit<ManualAlbum, "cover">,
    userId: string,
  ): Promise<Album>;
  storeCover(albumId: string, image: Image): Promise<string>;
  setCoverUrl(albumId: string, url: string): Promise<void>;
}

/** Largest photo accepted, decoded; the app scales photos to 500 px. */
export const maxCoverBytes = 2 * 1024 * 1024;

/** Reads and checks what the app sends for an album added by hand. */
export function parseManual(body: Record<string, unknown>): ManualAlbum {
  const text = (value: unknown, field: string) => {
    const s = typeof value === "string" ? value.trim() : "";
    if (s.length === 0 || s.length > 200) {
      throw new BadRequest(`${field} is required (at most 200 characters)`);
    }
    return s;
  };
  const year = body.year ?? null;
  if (
    year !== null &&
    (!Number.isInteger(year) || (year as number) < 1000 ||
      (year as number) > 2100)
  ) {
    throw new BadRequest("year must be a whole year");
  }
  let cover: Image | null = null;
  if (body.cover != null) {
    const c = body.cover as { data?: unknown; type?: unknown };
    if (c.type !== "image/jpeg" && c.type !== "image/png") {
      throw new BadRequest("cover must be a JPEG or PNG");
    }
    let bytes: Uint8Array;
    try {
      bytes = Uint8Array.from(atob(String(c.data)), (ch) => ch.charCodeAt(0));
    } catch {
      throw new BadRequest("cover is not base64");
    }
    if (bytes.length === 0 || bytes.length > maxCoverBytes) {
      throw new BadRequest("cover is empty or larger than 2 MB");
    }
    cover = { bytes, contentType: c.type };
  }
  return {
    title: text(body.title, "title"),
    artist: text(body.artist, "artist"),
    year: year as number | null,
    cover,
  };
}

export async function addManualAlbum(
  album: ManualAlbum,
  userId: string,
  deps: ManualDeps,
): Promise<Album> {
  const { cover, ...fields } = album;
  const added = await deps.insertManual(fields, userId);
  if (!cover) return added;
  const url = await deps.storeCover(added.id, cover);
  await deps.setCoverUrl(added.id, url);
  return { ...added, cover_url: url };
}
