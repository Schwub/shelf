// Shared Spotify and Bandcamp links: what they point to, and what their
// pages say about an album (docs/features/sharing.md).

export type Kind = "album" | "track" | "playlist" | "artist" | "other";

export interface Link {
  kind: Kind;
  /** The canonical link, as MusicBrainz stores it; null for short links. */
  url: string | null;
  /** spotify.link short links must be followed first. */
  short?: boolean;
}

/** What a Spotify or Bandcamp link points to, or null for other sites. */
export function parseLink(raw: string): Link | null {
  let u: URL;
  try {
    u = new URL(raw.trim());
  } catch {
    return null;
  }
  if (u.protocol !== "https:" && u.protocol !== "http:") return null;
  const host = u.hostname.toLowerCase();
  // Spotify adds a locale ("/intl-de/album/…") and tracking (?si=…).
  const parts = u.pathname.split("/").filter((p) =>
    p && !p.startsWith("intl-")
  );
  if (host === "spotify.link") return { kind: "other", url: null, short: true };
  if (host === "open.spotify.com") {
    const [type, id] = parts;
    if (!id || !/^[A-Za-z0-9]{22}$/.test(id)) {
      return { kind: "other", url: null };
    }
    const kind: Kind = type === "album" || type === "track" ||
        type === "playlist" || type === "artist"
      ? type
      : "other";
    return { kind, url: `https://open.spotify.com/${type}/${id}` };
  }
  if (/^[a-z0-9-]+\.bandcamp\.com$/.test(host)) {
    const [type, slug] = parts;
    if (type === "album" && slug) {
      return { kind: "album", url: `https://${host}/album/${slug}` };
    }
    return { kind: type === "track" ? "track" : "other", url: null };
  }
  return null;
}

export interface PageAlbum {
  title: string;
  artist: string;
  year: number | null;
  /** MusicBrainz primary type, to search for the right release group. */
  type: "Album" | "Single" | "EP";
  coverUrl: string | null;
}

const entities: Record<string, string> = {
  amp: "&",
  quot: '"',
  apos: "'",
  lt: "<",
  gt: ">",
};

function decode(s: string): string {
  return s.replace(/&(#x[0-9a-f]+|#\d+|\w+);/gi, (m, e: string) => {
    if (e[0] === "#") {
      return String.fromCodePoint(
        e[1].toLowerCase() === "x"
          ? parseInt(e.slice(2), 16)
          : parseInt(e.slice(1), 10),
      );
    }
    return entities[e.toLowerCase()] ?? m;
  });
}

function meta(html: string, property: string): string | null {
  const m = html.match(
    new RegExp(`<meta property="${property}" content="([^"]*)"`),
  );
  return m ? decode(m[1]) : null;
}

/** "Listen to OK Computer - Album by Radiohead | Spotify" and
 * "Radiohead · album · 1997 · 12 songs". */
export function spotifyPage(html: string): PageAlbum | null {
  const title = meta(html, "og:title")?.match(
    /^Listen to (.*) - (Album|EP|Single|Compilation) by (.*) \| Spotify$/,
  );
  if (!title) return null;
  const year = meta(html, "og:description")?.split(" · ")[2];
  const type = title[2] === "EP"
    ? "EP"
    : title[2] === "Single"
    ? "Single"
    : "Album";
  return {
    title: title[1],
    artist: title[3],
    year: year && /^\d{4}$/.test(year) ? Number(year) : null,
    type,
    coverUrl: meta(html, "og:image"),
  };
}

/** The album's JSON-LD (schema.org MusicAlbum) on a Bandcamp page. */
export function bandcampPage(html: string): PageAlbum | null {
  const script = html.match(
    /<script type="application\/ld\+json">([\s\S]*?)<\/script>/,
  );
  if (!script) return null;
  let ld: Record<string, unknown>;
  try {
    ld = JSON.parse(script[1]);
  } catch {
    return null;
  }
  const artist = (ld.byArtist as { name?: string } | undefined)?.name;
  if (typeof ld.name !== "string" || !artist) return null;
  const year = String(ld.datePublished ?? "").match(/\b(\d{4})\b/);
  const release = String(ld.albumReleaseType ?? "");
  return {
    title: ld.name,
    artist,
    year: year ? Number(year[1]) : null,
    type: release === "SingleRelease"
      ? "Single"
      : release === "EPRelease"
      ? "EP"
      : "Album",
    coverUrl: meta(html, "og:image"),
  };
}
