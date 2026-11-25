// Turns a shared link into an album: MusicBrainz URL lookup first, then the
// page's metadata and a MusicBrainz search (measured: 19 of 20 real links,
// docs/project.md). Network access is passed in, so tests need none.

import {
  bandcampPage,
  Kind,
  PageAlbum,
  parseLink,
  spotifyPage,
} from "./link.ts";

export interface Hit {
  musicbrainz_id: string;
  title: string;
  artist: string;
  year: number | null;
}

export type Resolved =
  | ({ kind: "album" } & Hit)
  /** Not on MusicBrainz: what the page says, for adding it by hand. */
  | {
    kind: "unknown";
    title: string;
    artist: string;
    year: number | null;
    cover_url: string | null;
  }
  | { kind: "not_album"; what: Kind };

export interface Deps {
  /** The page and the address it ended at (short links redirect). */
  fetchPage(url: string): Promise<{ url: string; html: string } | null>;
  urlLookup(url: string): Promise<Hit | null>;
  search(page: PageAlbum): Promise<Hit | null>;
}

export class Unsupported extends Error {}
export class NotFound extends Error {}

export async function resolve(raw: string, deps: Deps): Promise<Resolved> {
  let link = parseLink(raw);
  if (!link) throw new Unsupported(raw);
  let fetched: { url: string; html: string } | null = null;
  if (link.short) {
    fetched = await deps.fetchPage(raw);
    link = fetched && parseLink(fetched.url);
    if (!link || link.short) throw new NotFound(raw);
  }
  if (link.kind !== "album" || !link.url) {
    return { kind: "not_album", what: link.kind };
  }
  const known = await deps.urlLookup(link.url);
  if (known) return { kind: "album", ...known };

  fetched ??= await deps.fetchPage(link.url);
  if (!fetched) throw new NotFound(link.url);
  const page = link.url.includes("spotify.com")
    ? spotifyPage(fetched.html)
    : bandcampPage(fetched.html);
  if (!page) throw new NotFound(link.url);
  const found = await deps.search(page);
  if (found) return { kind: "album", ...found };
  return {
    kind: "unknown",
    title: page.title,
    artist: page.artist,
    year: page.year,
    cover_url: page.coverUrl,
  };
}
