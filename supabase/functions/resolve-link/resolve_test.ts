import assert from "node:assert/strict";
import { Deps, Hit, NotFound, resolve, Unsupported } from "./resolve.ts";

const album = `https://open.spotify.com/album/6dVIqQ8qmQ5GBnJ9shOYGE`;
const okComputer: Hit = {
  musicbrainz_id: "b1392450-e666-3926-a536-22c65f834433",
  title: "OK Computer",
  artist: "Radiohead",
  year: 1997,
};
const page =
  `<meta property="og:title" content="Listen to OK Computer - Album by Radiohead | Spotify"/>
<meta property="og:description" content="Radiohead · album · 1997 · 12 songs"/>
<meta property="og:image" content="https://i.scdn.co/image/cover"/>`;

/** Deps that answer from the given maps and record the calls. */
function fakeDeps(
  pages: Record<string, { url: string; html: string }>,
  known: Record<string, Hit> = {},
  found: Hit | null = null,
) {
  const calls: string[] = [];
  const deps: Deps = {
    fetchPage: (url) => {
      calls.push(`page ${url}`);
      return Promise.resolve(pages[url] ?? null);
    },
    urlLookup: (url) => {
      calls.push(`lookup ${url}`);
      return Promise.resolve(known[url] ?? null);
    },
    search: (p) => {
      calls.push(`search ${p.title}`);
      return Promise.resolve(found);
    },
  };
  return { deps, calls };
}

Deno.test("an album MusicBrainz links to needs no page", async () => {
  const { deps, calls } = fakeDeps({}, { [album]: okComputer });
  assert.deepEqual(await resolve(`${album}?si=x`, deps), {
    kind: "album",
    ...okComputer,
  });
  assert.deepEqual(calls, [`lookup ${album}`]);
});

Deno.test("otherwise searches with what the page says", async () => {
  const { deps, calls } = fakeDeps(
    { [album]: { url: album, html: page } },
    {},
    okComputer,
  );
  assert.deepEqual(await resolve(album, deps), {
    kind: "album",
    ...okComputer,
  });
  assert.deepEqual(calls, [
    `lookup ${album}`,
    `page ${album}`,
    "search OK Computer",
  ]);
});

Deno.test("an album MusicBrainz doesn't know comes back from its page", async () => {
  const { deps } = fakeDeps({ [album]: { url: album, html: page } });
  assert.deepEqual(await resolve(album, deps), {
    kind: "unknown",
    title: "OK Computer",
    artist: "Radiohead",
    year: 1997,
    cover_url: "https://i.scdn.co/image/cover",
  });
});

Deno.test("follows short links", async () => {
  const short = "https://spotify.link/AbCdEf";
  const { deps, calls } = fakeDeps(
    { [short]: { url: `${album}?si=x`, html: page } },
    {},
    okComputer,
  );
  assert.equal((await resolve(short, deps)).kind, "album");
  // The page the short link ended at is read only once.
  assert.deepEqual(calls, [
    `page ${short}`,
    `lookup ${album}`,
    "search OK Computer",
  ]);
});

Deno.test("names what a link is when it isn't an album", async () => {
  const { deps, calls } = fakeDeps({});
  assert.deepEqual(
    await resolve(
      "https://open.spotify.com/track/6dVIqQ8qmQ5GBnJ9shOYGE",
      deps,
    ),
    { kind: "not_album", what: "track" },
  );
  assert.deepEqual(calls, []);
});

Deno.test("rejects other sites, and pages that are gone", async () => {
  const { deps } = fakeDeps({});
  await assert.rejects(resolve("https://example.com/a", deps), Unsupported);
  await assert.rejects(resolve(album, deps), NotFound);
  await assert.rejects(resolve("https://spotify.link/gone", deps), NotFound);
  const { deps: blank } = fakeDeps({ [album]: { url: album, html: "" } });
  await assert.rejects(resolve(album, blank), NotFound);
});
