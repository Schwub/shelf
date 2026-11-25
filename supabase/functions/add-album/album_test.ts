import assert from "node:assert/strict";
import { addAlbum, Album, BadRequest, Deps } from "./album.ts";
import { Image, ReleaseGroup } from "./musicbrainz.ts";

const id = "b1392450-e666-3926-a536-22c65f834433";
const group: ReleaseGroup = {
  musicbrainz_id: id,
  title: "OK Computer",
  artist: "Radiohead",
  year: 1997,
};
const image: Image = {
  bytes: new Uint8Array([1, 2]),
  contentType: "image/jpeg",
};

/** An in-memory catalog; records what the function did. */
function fakes(
  { albums = [] as Album[], coverImage = image as Image | null } = {},
) {
  const calls: string[] = [];
  const deps: Deps = {
    findAlbum: (mbid) =>
      Promise.resolve(albums.find((a) => a.musicbrainz_id === mbid) ?? null),
    releaseGroup: (mbid) => {
      calls.push(`releaseGroup ${mbid}`);
      return Promise.resolve(group);
    },
    insertAlbum: (g) => {
      const album = { id: "album-1", cover_url: null, ...g };
      albums.push(album);
      calls.push("insert");
      return Promise.resolve(album);
    },
    cover: () => {
      calls.push("cover");
      return Promise.resolve(coverImage);
    },
    storeCover: (albumId) => {
      calls.push(`store ${albumId}`);
      return Promise.resolve(`https://covers/${albumId}.jpg`);
    },
    setCoverUrl: (albumId, url) => {
      albums.find((a) => a.id === albumId)!.cover_url = url;
      return Promise.resolve();
    },
  };
  return { deps, calls, albums };
}

Deno.test("a new album is added with its cover copied", async () => {
  const { deps, calls, albums } = fakes();
  const album = await addAlbum(id, deps);
  assert.deepEqual(album, {
    id: "album-1",
    ...group,
    cover_url: "https://covers/album-1.jpg",
  });
  assert.deepEqual(calls, [
    `releaseGroup ${id}`,
    "insert",
    "cover",
    "store album-1",
  ]);
  assert.equal(albums[0].cover_url, "https://covers/album-1.jpg");
});

Deno.test("an album already in the catalog is returned as it is", async () => {
  const existing = { id: "a", ...group, cover_url: "https://covers/a.jpg" };
  const { deps, calls } = fakes({ albums: [existing] });
  assert.deepEqual(await addAlbum(id, deps), existing);
  assert.deepEqual(calls, []);
});

Deno.test("an album without a cover gets another try", async () => {
  const existing = { id: "a", ...group, cover_url: null };
  const { deps, calls } = fakes({ albums: [existing] });
  const album = await addAlbum(id, deps);
  assert.equal(album.cover_url, "https://covers/a.jpg");
  assert.deepEqual(calls, ["cover", "store a"]);
});

Deno.test("no cover: the album is still added", async () => {
  const { deps, calls } = fakes({ coverImage: null });
  const album = await addAlbum(id, deps);
  assert.equal(album.cover_url, null);
  assert.deepEqual(calls, [`releaseGroup ${id}`, "insert", "cover"]);
});

Deno.test("a request that loses the insert race gets the other's album", async () => {
  const winner = {
    id: "first",
    ...group,
    cover_url: "https://covers/first.jpg",
  };
  let found = 0;
  const { deps } = fakes();
  deps.findAlbum = () => Promise.resolve(found++ === 0 ? null : winner);
  deps.insertAlbum = () => Promise.resolve(null);
  assert.deepEqual(await addAlbum(id, deps), winner);
});

Deno.test("anything but a MusicBrainz ID is refused", async () => {
  const { deps, calls } = fakes();
  await assert.rejects(addAlbum("'; drop table albums", deps), BadRequest);
  assert.deepEqual(calls, []);
});
