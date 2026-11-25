import assert from "node:assert/strict";
import {
  addManualAlbum,
  Album,
  BadRequest,
  ManualDeps,
  maxCoverBytes,
  parseManual,
} from "./album.ts";

const jpeg = btoa(String.fromCharCode(0xff, 0xd8, 0xff, 0xe0));

Deno.test("reads title, artist, year and the photo", () => {
  const album = parseManual({
    title: "  Demo tape ",
    artist: "The Locals",
    year: 1994,
    cover: { data: jpeg, type: "image/jpeg" },
  });
  assert.equal(album.title, "Demo tape");
  assert.equal(album.year, 1994);
  assert.deepEqual(
    album.cover?.bytes,
    new Uint8Array([0xff, 0xd8, 0xff, 0xe0]),
  );
});

Deno.test("year and photo are optional", () => {
  const album = parseManual({ title: "A", artist: "B" });
  assert.equal(album.year, null);
  assert.equal(album.cover, null);
});

Deno.test("refuses missing names, odd years and wrong photos", () => {
  for (
    const body of [
      { artist: "B" },
      { title: "  ", artist: "B" },
      { title: "A", artist: "B".repeat(201) },
      { title: "A", artist: "B", year: 19 },
      { title: "A", artist: "B", year: "1994" },
      { title: "A", artist: "B", cover: { data: jpeg, type: "image/gif" } },
      { title: "A", artist: "B", cover: { data: "%%%", type: "image/png" } },
      { title: "A", artist: "B", cover: { data: "", type: "image/png" } },
    ]
  ) {
    assert.throws(() => parseManual(body), BadRequest, JSON.stringify(body));
  }
});

Deno.test("refuses a photo larger than 2 MB", () => {
  const big = btoa("x".repeat(maxCoverBytes + 1));
  assert.throws(
    () =>
      parseManual({
        title: "A",
        artist: "B",
        cover: { data: big, type: "image/jpeg" },
      }),
    BadRequest,
  );
});

function fakes() {
  const calls: string[] = [];
  const deps: ManualDeps = {
    insertManual: (fields, userId) => {
      calls.push(`insert ${fields.title} by ${userId}`);
      const album: Album = {
        id: "m1",
        musicbrainz_id: null,
        title: fields.title,
        artist: fields.artist,
        year: fields.year,
        cover_url: null,
      };
      return Promise.resolve(album);
    },
    storeCover: (id) => {
      calls.push(`store ${id}`);
      return Promise.resolve(`https://covers/${id}.jpg`);
    },
    setCoverUrl: () => Promise.resolve(),
  };
  return { deps, calls };
}

Deno.test("adds the album as the user's, with the photo as cover", async () => {
  const { deps, calls } = fakes();
  const album = await addManualAlbum(
    parseManual({
      title: "Demo",
      artist: "Locals",
      cover: { data: jpeg, type: "image/jpeg" },
    }),
    "user-1",
    deps,
  );
  assert.equal(album.cover_url, "https://covers/m1.jpg");
  assert.deepEqual(calls, ["insert Demo by user-1", "store m1"]);
});

Deno.test("without a photo there is nothing to store", async () => {
  const { deps, calls } = fakes();
  const album = await addManualAlbum(
    parseManual({ title: "Demo", artist: "Locals" }),
    "user-1",
    deps,
  );
  assert.equal(album.cover_url, null);
  assert.deepEqual(calls, ["insert Demo by user-1"]);
});
