import assert from "node:assert/strict";
import type { Fetch } from "../add-album/musicbrainz.ts";
import { search, urlLookup } from "./musicbrainz.ts";

const groupId = "b1392450-e666-3926-a536-22c65f834433";
const releaseId = "0b6b4ba0-d36f-47bd-b4ea-6a5b91842d29";
const agent = "shelf/1.0 ( contact )";

/** Answers requests in turn and records their URLs. */
function fakeFetch(...responses: (() => Response)[]) {
  const urls: string[] = [];
  const fn: Fetch = (input) => {
    urls.push(decodeURIComponent(String(input)));
    return Promise.resolve(responses[urls.length - 1]());
  };
  return { fn, urls };
}

// The fields shelf uses (recorded shapes).
const urlEntry = {
  resource: "https://open.spotify.com/album/6dVIqQ8qmQ5GBnJ9shOYGE",
  relations: [{ type: "free streaming", release: { id: releaseId } }],
};
const release = {
  id: releaseId,
  "artist-credit": [{ name: "Radiohead", joinphrase: "" }],
  "release-group": {
    id: groupId,
    title: "OK Computer",
    "first-release-date": "1997-05-21",
  },
};
const okComputer = {
  musicbrainz_id: groupId,
  title: "OK Computer",
  artist: "Radiohead",
  year: 1997,
};

Deno.test("finds the release group of a linked release", async () => {
  const { fn, urls } = fakeFetch(
    () => Response.json(urlEntry),
    () => Response.json(release),
  );
  assert.deepEqual(
    await urlLookup(urlEntry.resource, fn, agent, 0),
    okComputer,
  );
  assert.match(urls[0], /\/url\?resource=https:\/\/open\.spotify\.com\//);
  assert.match(urls[1], new RegExp(`/release/${releaseId}\\?`));
});

Deno.test("a URL MusicBrainz doesn't know is no hit", async () => {
  const unknown = fakeFetch(() => new Response("", { status: 404 }));
  assert.equal(await urlLookup(urlEntry.resource, unknown.fn, agent, 0), null);
  const noRelease = fakeFetch(() => Response.json({ relations: [] }));
  assert.equal(
    await urlLookup(urlEntry.resource, noRelease.fn, agent, 0),
    null,
  );
});

Deno.test("retries twice when MusicBrainz is busy", async () => {
  const { fn, urls } = fakeFetch(
    () => new Response("", { status: 503 }),
    () => new Response("", { status: 503 }),
    () => Response.json(urlEntry),
    () => Response.json(release),
  );
  assert.deepEqual(
    await urlLookup(urlEntry.resource, fn, agent, 0),
    okComputer,
  );
  assert.equal(urls.length, 4);
  const busy = fakeFetch(
    () => new Response("", { status: 503 }),
    () => new Response("", { status: 503 }),
    () => new Response("", { status: 503 }),
  );
  await assert.rejects(urlLookup(urlEntry.resource, busy.fn, agent, 0));
});

const page = {
  title: "OK Computer",
  artist: "Radiohead",
  year: 1997,
  type: "Album" as const,
  coverUrl: null,
};

Deno.test("searches by title, artist and type", async () => {
  const { fn, urls } = fakeFetch(() =>
    Response.json({
      "release-groups": [
        {
          id: "other",
          title: "OK Computer OKNOTOK 1997 2017",
          "artist-credit": [{ name: "Radiohead" }],
        },
        {
          ...release["release-group"],
          "artist-credit": release["artist-credit"],
        },
      ],
    })
  );
  assert.deepEqual(await search(page, fn, agent, 0), okComputer);
  assert.match(
    urls[0],
    /query=releasegroup:"OK Computer" AND artist:"Radiohead" AND primarytype:Album/,
  );
});

Deno.test("matches titles loosely but not other artists", async () => {
  const groups = (artist: string) => () =>
    Response.json({
      "release-groups": [{
        id: groupId,
        title: "Ok computer!",
        "artist-credit": [{ name: artist }],
      }],
    });
  assert.equal(
    (await search(page, fakeFetch(groups("Radiohead")).fn, agent, 0))?.year,
    null,
  );
  assert.equal(
    await search(page, fakeFetch(groups("Coldplay")).fn, agent, 0),
    null,
  );
});

Deno.test("matches non-Latin titles by their letters", async () => {
  const groups = () =>
    Response.json({
      "release-groups": [{
        id: groupId,
        title: "ボーイ",
        "artist-credit": [{ name: "Ichiko Aoba" }],
      }],
    });
  const aoba = { ...page, artist: "Ichiko Aoba" };
  assert.equal(
    (await search({ ...aoba, title: "ボーイ" }, fakeFetch(groups).fn, agent, 0))
      ?.musicbrainz_id,
    groupId,
  );
  assert.equal(
    await search({ ...aoba, title: "アダン" }, fakeFetch(groups).fn, agent, 0),
    null,
  );
});

Deno.test("quotes titles with quote marks", async () => {
  const { fn, urls } = fakeFetch(() => Response.json({ "release-groups": [] }));
  await search({ ...page, title: 'Say "Hi"' }, fn, agent, 0);
  assert.match(urls[0], /releasegroup:"Say \\"Hi\\""/);
});

Deno.test("spaces requests to keep to the rate limit", async () => {
  const { fn } = fakeFetch(
    () => Response.json(urlEntry),
    () => Response.json(release),
  );
  const start = Date.now();
  await urlLookup(urlEntry.resource, fn, agent, 50);
  assert.ok(Date.now() - start >= 50);
});
