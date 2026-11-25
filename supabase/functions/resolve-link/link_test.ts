import assert from "node:assert/strict";
import { bandcampPage, parseLink, spotifyPage } from "./link.ts";

const spotifyId = "6dVIqQ8qmQ5GBnJ9shOYGE";

Deno.test("canonicalizes Spotify album links", () => {
  for (
    const raw of [
      `https://open.spotify.com/album/${spotifyId}`,
      `https://open.spotify.com/intl-de/album/${spotifyId}?si=abc123`,
      ` http://open.spotify.com/album/${spotifyId} `,
    ]
  ) {
    assert.deepEqual(parseLink(raw), {
      kind: "album",
      url: `https://open.spotify.com/album/${spotifyId}`,
    });
  }
});

Deno.test("tells Spotify tracks, playlists and artists apart", () => {
  assert.equal(
    parseLink(`https://open.spotify.com/track/${spotifyId}`)?.kind,
    "track",
  );
  assert.equal(
    parseLink(`https://open.spotify.com/playlist/${spotifyId}`)?.kind,
    "playlist",
  );
  assert.equal(
    parseLink(`https://open.spotify.com/artist/${spotifyId}`)?.kind,
    "artist",
  );
  assert.equal(
    parseLink("https://open.spotify.com/album/short")?.kind,
    "other",
  );
});

Deno.test("marks spotify.link short links to be followed", () => {
  assert.deepEqual(parseLink("https://spotify.link/AbCdEf"), {
    kind: "other",
    url: null,
    short: true,
  });
});

Deno.test("canonicalizes Bandcamp album links", () => {
  assert.deepEqual(
    parseLink("https://radiohead.bandcamp.com/album/ok-computer?from=x#t1"),
    { kind: "album", url: "https://radiohead.bandcamp.com/album/ok-computer" },
  );
  assert.equal(
    parseLink("https://radiohead.bandcamp.com/track/airbag")?.kind,
    "track",
  );
  assert.equal(parseLink("https://radiohead.bandcamp.com/")?.kind, "other");
});

Deno.test("rejects other sites and non-links", () => {
  assert.equal(parseLink("https://music.apple.com/album/1"), null);
  assert.equal(parseLink("not a link"), null);
  assert.equal(parseLink(`ftp://open.spotify.com/album/${spotifyId}`), null);
});

// Recorded from open.spotify.com, trimmed to the tags shelf reads.
const spotifyHtml = `<head>
<meta property="og:title" content="Listen to OK Computer - Album by Radiohead | Spotify"/>
<meta property="og:description" content="Radiohead · album · 1997 · 12 songs"/>
<meta property="og:image" content="https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856"/>
</head>`;

Deno.test("reads an album from its Spotify page", () => {
  assert.deepEqual(spotifyPage(spotifyHtml), {
    title: "OK Computer",
    artist: "Radiohead",
    year: 1997,
    type: "Album",
    coverUrl:
      "https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856",
  });
});

Deno.test("decodes entities and reads EPs and singles on Spotify", () => {
  const page = spotifyPage(
    `<meta property="og:title" content="Listen to Drums &amp; Guns - EP by Low &#x26; Friends | Spotify"/>`,
  );
  assert.equal(page?.title, "Drums & Guns");
  assert.equal(page?.artist, "Low & Friends");
  assert.equal(page?.type, "EP");
  assert.equal(page?.year, null);
  assert.equal(
    spotifyPage(
      `<meta property="og:title" content="Listen to Creep - Single by Radiohead | Spotify"/>`,
    )?.type,
    "Single",
  );
  assert.equal(spotifyPage("<html></html>"), null);
});

// Recorded from radiohead.bandcamp.com, trimmed to what shelf reads.
const bandcampHtml = `<head>
<meta property="og:image" content="https://f4.bcbits.com/img/a1866183002_5.jpg">
<script type="application/ld+json">
{"@type":"MusicAlbum","name":"OK Computer OKNOTOK 1997 2017",
 "byArtist":{"@type":"MusicGroup","name":"Radiohead"},
 "datePublished":"23 Jun 2017 00:00:00 GMT","albumReleaseType":"AlbumRelease"}
</script></head>`;

Deno.test("reads an album from its Bandcamp page", () => {
  assert.deepEqual(bandcampPage(bandcampHtml), {
    title: "OK Computer OKNOTOK 1997 2017",
    artist: "Radiohead",
    year: 2017,
    type: "Album",
    coverUrl: "https://f4.bcbits.com/img/a1866183002_5.jpg",
  });
  assert.equal(
    bandcampPage(bandcampHtml.replace("AlbumRelease", "EPRelease"))?.type,
    "EP",
  );
  assert.equal(
    bandcampPage('<script type="application/ld+json">{</script>'),
    null,
  );
  assert.equal(bandcampPage("<html></html>"), null);
});
