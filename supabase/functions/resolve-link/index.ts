// POST { "url": "<shared Spotify or Bandcamp link>" } → what it is:
// { kind: "album", musicbrainz_id, title, artist, year },
// { kind: "unknown", title, artist, year, cover_url } (not on MusicBrainz),
// or { kind: "not_album", what } (a track, playlist, artist …).
// 400 for other sites, 404 when the page is gone. Signed-in users only (the
// platform checks the JWT). Runs on the server, where the pages can be read
// without the browser's cross-site limits.

import { userAgent } from "../add-album/musicbrainz.ts";
import { search, urlLookup } from "./musicbrainz.ts";
import { NotFound, resolve, Unsupported } from "./resolve.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const agent = userAgent(Deno.env.get("MUSICBRAINZ_CONTACT"));

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  try {
    const { url } = await request.json();
    return json(
      await resolve(String(url ?? ""), {
        fetchPage: async (pageUrl) => {
          // The contact is for MusicBrainz only.
          const response = await fetch(pageUrl, {
            headers: { "User-Agent": userAgent(undefined) },
            redirect: "follow",
          });
          if (!response.ok) return null;
          return { url: response.url, html: await response.text() };
        },
        urlLookup: (link) => urlLookup(link, fetch, agent),
        search: (page) => search(page, fetch, agent),
      }),
    );
  } catch (e) {
    if (e instanceof Unsupported) return json({ error: "unsupported" }, 400);
    if (e instanceof NotFound) return json({ error: "not_found" }, 404);
    console.error(e);
    return json({ error: "failed" }, 502);
  }
});
