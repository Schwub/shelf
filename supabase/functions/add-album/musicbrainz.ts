// MusicBrainz and the Cover Art Archive, with fetch passed in for tests.

export type Fetch = typeof fetch;

/**
 * MusicBrainz asks every client for a User-Agent with a contact. The
 * contact comes from the MUSICBRAINZ_CONTACT secret, set per environment.
 */
export function userAgent(contact: string | undefined): string {
  return contact ? `shelf/1.0 ( ${contact} )` : "shelf/1.0";
}

export interface ReleaseGroup {
  musicbrainz_id: string;
  title: string;
  artist: string;
  year: number | null;
}

export class NotFound extends Error {}

/** The album (release group) with this MusicBrainz ID. */
export async function releaseGroup(
  id: string,
  fetchFn: Fetch,
  agent: string,
): Promise<ReleaseGroup> {
  const response = await fetchFn(
    `https://musicbrainz.org/ws/2/release-group/${id}?inc=artist-credits&fmt=json`,
    { headers: { "User-Agent": agent, Accept: "application/json" } },
  );
  if (response.status === 404) throw new NotFound(id);
  if (!response.ok) {
    throw new Error(`MusicBrainz answered ${response.status}`);
  }
  const group = await response.json();
  const credits: { name: string; joinphrase?: string }[] =
    group["artist-credit"] ?? [];
  const year = Number.parseInt(
    (group["first-release-date"] ?? "").slice(0, 4),
  );
  return {
    musicbrainz_id: group.id,
    title: group.title,
    artist: credits.map((c) => c.name + (c.joinphrase ?? "")).join("").trim(),
    year: Number.isNaN(year) ? null : year,
  };
}

export interface Image {
  bytes: Uint8Array;
  contentType: string;
}

/**
 * The 500 px front cover, or null when the album has none or the download
 * fails: the album is added without a cover then.
 */
export async function cover(
  id: string,
  fetchFn: Fetch,
  agent: string,
): Promise<Image | null> {
  try {
    const response = await fetchFn(
      `https://coverartarchive.org/release-group/${id}/front-500`,
      { headers: { "User-Agent": agent } },
    );
    const contentType = response.headers.get("content-type") ?? "";
    if (!response.ok || !contentType.startsWith("image/")) return null;
    return {
      bytes: new Uint8Array(await response.arrayBuffer()),
      contentType,
    };
  } catch {
    return null;
  }
}
