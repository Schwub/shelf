// POST { "musicbrainz_id": "<release group id>" } → the album, added to the
// shared catalog with its cover if it wasn't there yet. Signed-in users only
// (the platform checks the JWT); writes with the service role, since users
// can't add albums or covers themselves.

import { createClient } from "npm:@supabase/supabase-js@2.49.4";
import { addAlbum, BadRequest } from "./album.ts";
import { cover, NotFound, releaseGroup, userAgent } from "./musicbrainz.ts";

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

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const columns = "id, musicbrainz_id, title, artist, year, cover_url";
const agent = userAgent(Deno.env.get("MUSICBRAINZ_CONTACT"));

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  try {
    const { musicbrainz_id } = await request.json();
    const album = await addAlbum(String(musicbrainz_id), {
      findAlbum: async (id) => {
        const { data, error } = await db.from("albums").select(columns)
          .eq("musicbrainz_id", id).maybeSingle();
        if (error) throw error;
        return data;
      },
      releaseGroup: (id) => releaseGroup(id, fetch, agent),
      insertAlbum: async (group) => {
        const { data, error } = await db.from("albums")
          .upsert(group, {
            onConflict: "musicbrainz_id",
            ignoreDuplicates: true,
          })
          .select(columns);
        if (error) throw error;
        return data[0] ?? null;
      },
      cover: (id) => cover(id, fetch, agent),
      storeCover: async (albumId, image) => {
        const path = `${albumId}.jpg`;
        const { error } = await db.storage.from("covers")
          .upload(path, image.bytes, {
            contentType: image.contentType,
            upsert: true,
          });
        if (error) throw error;
        return db.storage.from("covers").getPublicUrl(path).data.publicUrl;
      },
      setCoverUrl: async (albumId, url) => {
        const { error } = await db.from("albums").update({ cover_url: url })
          .eq("id", albumId);
        if (error) throw error;
      },
    });
    return json(album);
  } catch (e) {
    if (e instanceof BadRequest) return json({ error: "bad_request" }, 400);
    if (e instanceof NotFound) return json({ error: "not_found" }, 404);
    console.error(e);
    return json({ error: "failed" }, 502);
  }
});
