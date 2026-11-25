begin;
select plan(5);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com');

select results_eq(
  $$select public from storage.buckets where id = 'covers'$$,
  array[true], 'covers can be read by anyone');

-- The add-album function (service role) stores a cover.
insert into storage.objects (bucket_id, name) values ('covers', 'a.jpg');

select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$insert into storage.objects (bucket_id, name) values ('covers', 'b.jpg')$$,
  '42501', null, 'users cannot upload covers');
update storage.objects set name = 'replaced.jpg' where bucket_id = 'covers';

reset role;
select results_eq(
  $$select name from storage.objects
    where bucket_id = 'covers' and name in ('a.jpg', 'replaced.jpg')$$,
  array['a.jpg'], 'users cannot replace covers');

set local role anon;
select throws_ok(
  $$insert into storage.objects (bucket_id, name) values ('covers', 'c.jpg')$$,
  '42501', null, 'anonymous users cannot upload covers');
reset role;

select is(
  (select count(*)::int from storage.buckets where id = 'covers' and 'image/jpeg' = any(allowed_mime_types)),
  1, 'covers accept JPEG');

select * from finish();
rollback;
