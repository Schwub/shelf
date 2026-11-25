// The MusicBrainz side of resolving a link, with fetch passed in for tests.

import type { Fetch } from "../add-album/musicbrainz.ts";
import type { PageAlbum } from "./link.ts";
import type { Hit } from "./resolve.ts";

const api = "https://musicbrainz.org/ws/2";

const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));
let last = 0;

/**
 * GET at most one request per [gap] ms (MusicBrainz's rate limit; a link
 * takes up to three), with one retry when MusicBrainz is busy anyway (503).
 */
async function get(
  url: string,
  fetchFn: Fetch,
  agent: string,
  gap: number,
): Promise<Record<string, unknown> | null> {
  const once = async () => {
    await wait(last + gap - Date.now());
    last = Date.now();
    return fetchFn(url, {
      headers: { "User-Agent": agent, Accept: "application/json" },
    });
  };
  let response = await once();
  if (response.status === 503) response = await once();
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`MusicBrainz answered ${response.status}`);
  return await response.json();
}

type Credit = { name: string; joinphrase?: string };
const artistOf = (credits: Credit[] = []) =>
  credits.map((c) => c.name + (c.joinphrase ?? "")).join("").trim();
const yearOf = (date: unknown) => {
  const y = Number.parseInt(String(date ?? "").slice(0, 4));
  return Number.isNaN(y) ? null : y;
};

/** The release group of the release MusicBrainz links to this URL. */
export async function urlLookup(
  url: string,
  fetchFn: Fetch,
  agent: string,
  gap = 1100,
): Promise<Hit | null> {
  const entry = await get(
    `${api}/url?resource=${encodeURIComponent(url)}&inc=release-rels&fmt=json`,
    fetchFn,
    agent,
    gap,
  );
  const relations = (entry?.relations ?? []) as { release?: { id: string } }[];
  const release = relations.find((r) => r.release)?.release;
  if (!release) return null;
  const full = await get(
    `${api}/release/${release.id}?inc=release-groups+artist-credits&fmt=json`,
    fetchFn,
    agent,
    gap,
  );
  const group = full?.["release-group"] as
    | { id: string; title: string; "first-release-date"?: string }
    | undefined;
  if (!group) return null;
  return {
    musicbrainz_id: group.id,
    title: group.title,
    artist: artistOf(full!["artist-credit"] as Credit[]),
    year: yearOf(group["first-release-date"]),
  };
}

const norm = (s: string) =>
  s.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase()
    .replace(/[^a-z0-9]+/g, " ").trim();
const quote = (s: string) => `"${s.replace(/[\\"]/g, (c) => "\\" + c)}"`;

/**
 * The release group with the page's title, artist and type. Without the
 * type, an album and the single of the same name are both "found".
 */
export async function search(
  page: PageAlbum,
  fetchFn: Fetch,
  agent: string,
  gap = 1100,
): Promise<Hit | null> {
  const query = `releasegroup:${quote(page.title)} AND artist:${
    quote(page.artist)
  } AND primarytype:${page.type}`;
  const result = await get(
    `${api}/release-group?query=${encodeURIComponent(query)}&limit=5&fmt=json`,
    fetchFn,
    agent,
    gap,
  );
  const groups = (result?.["release-groups"] ?? []) as {
    id: string;
    title: string;
    "artist-credit"?: Credit[];
    "first-release-date"?: string;
  }[];
  const match = groups.find((g) =>
    norm(g.title) === norm(page.title) &&
    norm(artistOf(g["artist-credit"])).includes(norm(page.artist))
  );
  return match
    ? {
      musicbrainz_id: match.id,
      title: match.title,
      artist: artistOf(match["artist-credit"]),
      year: yearOf(match["first-release-date"]),
    }
    : null;
}
