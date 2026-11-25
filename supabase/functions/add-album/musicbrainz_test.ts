import assert from "node:assert/strict";
import {
  cover,
  Fetch,
  NotFound,
  releaseGroup,
  userAgent,
} from "./musicbrainz.ts";

const id = "b1392450-e666-3926-a536-22c65f834433";

/** Answers every request with [response] and records the requests. */
function fakeFetch(response: () => Response) {
  const requests: { url: string; agent: string | null }[] = [];
  const fn: Fetch = (input, init) => {
    requests.push({
      url: String(input),
      agent: new Headers(init?.headers).get("User-Agent"),
    });
    return Promise.resolve(response());
  };
  return { fn, requests };
}

// The fields shelf uses from a MusicBrainz release group (recorded shape).
const okComputer = {
  id,
  title: "OK Computer",
  "first-release-date": "1997-05-21",
  "primary-type": "Album",
  "artist-credit": [{ name: "Radiohead", joinphrase: "" }],
};

Deno.test("reads title, artist and year of a release group", async () => {
  const { fn, requests } = fakeFetch(() => Response.json(okComputer));
  assert.deepEqual(await releaseGroup(id, fn, "shelf/1.0 ( contact )"), {
    musicbrainz_id: id,
    title: "OK Computer",
    artist: "Radiohead",
    year: 1997,
  });
  assert.equal(
    requests[0].url,
    `https://musicbrainz.org/ws/2/release-group/${id}?inc=artist-credits&fmt=json`,
  );
  assert.equal(requests[0].agent, "shelf/1.0 ( contact )");
});

Deno.test("joins several artists and allows a missing date", async () => {
  const { fn } = fakeFetch(() =>
    Response.json({
      ...okComputer,
      "first-release-date": "",
      "artist-credit": [
        { name: "Floating Points", joinphrase: ", " },
        { name: "Pharoah Sanders", joinphrase: " & " },
        { name: "London Symphony Orchestra" },
      ],
    })
  );
  const group = await releaseGroup(id, fn, "shelf/1.0");
  assert.equal(
    group.artist,
    "Floating Points, Pharoah Sanders & London Symphony Orchestra",
  );
  assert.equal(group.year, null);
});

Deno.test("an unknown ID is NotFound, other errors fail", async () => {
  await assert.rejects(
    releaseGroup(id, fakeFetch(() => new Response("", { status: 404 })).fn, ""),
    NotFound,
  );
  await assert.rejects(
    releaseGroup(id, fakeFetch(() => new Response("", { status: 500 })).fn, ""),
    /500/,
  );
});

Deno.test("downloads the 500 px front cover", async () => {
  const { fn, requests } = fakeFetch(() =>
    new Response(new Uint8Array([7, 8]), {
      headers: { "content-type": "image/jpeg" },
    })
  );
  assert.deepEqual(await cover(id, fn, "shelf/1.0"), {
    bytes: new Uint8Array([7, 8]),
    contentType: "image/jpeg",
  });
  assert.equal(
    requests[0].url,
    `https://coverartarchive.org/release-group/${id}/front-500`,
  );
});

Deno.test("no cover, an error page or a network failure give null", async () => {
  assert.equal(
    await cover(id, fakeFetch(() => new Response("", { status: 404 })).fn, ""),
    null,
  );
  assert.equal(
    await cover(id, fakeFetch(() => new Response("<html>")).fn, ""),
    null,
  );
  const failing: Fetch = () => Promise.reject(new TypeError("offline"));
  assert.equal(await cover(id, failing, ""), null);
});

Deno.test("the User-Agent carries the contact when one is set", () => {
  assert.equal(
    userAgent("someone@example.com"),
    "shelf/1.0 ( someone@example.com )",
  );
  assert.equal(userAgent(undefined), "shelf/1.0");
  assert.equal(userAgent(""), "shelf/1.0");
});

Deno.test("a busy MusicBrainz (503) gets one retry", async () => {
  let calls = 0;
  const busyOnce = fakeFetch(() =>
    calls++ === 0
      ? new Response("", { status: 503 })
      : Response.json(okComputer)
  );
  assert.equal(
    (await releaseGroup(id, busyOnce.fn, "", 0)).title,
    "OK Computer",
  );
  assert.equal(busyOnce.requests.length, 2);

  const busy = fakeFetch(() => new Response("", { status: 503 }));
  await assert.rejects(releaseGroup(id, busy.fn, "", 0), /503/);
  assert.equal(busy.requests.length, 2);
});
