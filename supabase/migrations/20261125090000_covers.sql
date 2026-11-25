-- Albums come only from the add-album function (service role), which also
-- copies their covers into the covers bucket (docs/features/search.md).
drop policy "Signed-in users add albums" on public.albums;

-- Public for reading; no policies on storage.objects for this bucket, so
-- only the service role writes covers.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('covers', 'covers', true, 2097152, array['image/jpeg', 'image/png']);
