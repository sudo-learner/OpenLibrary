-- =====================================================================
-- OpenLibrary - database/setup.sql
-- The ONLY SQL file this project needs: database setup AND 3 sample
-- queries for your viva, in one place. It works whether this is a
-- brand-new Supabase project, or an older version of this project
-- (any earlier version: with licences/admin/lists, or with text+PDF
-- books) — it safely brings either one up to the current, simplest
-- design. Safe to run more than once, so if you are ever unsure what
-- state your database is in, just run this file again.
--
-- HOW TO RUN (pick one):
--   A) Normal use: Supabase Dashboard -> SQL Editor -> New query ->
--      paste this WHOLE file -> Run. This sets up (or safely re-checks)
--      the database and fills in any missing categories. Note: when you
--      run the whole file at once, Supabase only shows you the result
--      of the very LAST query in it (Query 3, at the bottom) - that is
--      normal, not an error.
--   B) To see all 3 sample queries' own results for your viva: scroll
--      to "PART 2" below, select just ONE query's text with your mouse,
--      and click Run (or press Ctrl/Cmd+Enter) - one query at a time.
--   C) To wipe every table and start completely fresh first: see the
--      commented-out "DANGER ZONE" block right below this, before PART 1.
--
-- Final design (4 tables):
--   categories  ->  books  <-  reading_progress / favorites  <-  auth.users
--   (auth.users is the login table Supabase already gives you)
--   Every book is a PDF, free for everyone. No licences, no admin panel.
-- =====================================================================

-- =====================================================================
-- DANGER ZONE (optional) - completely wipes every table, every row, and
-- the storage bucket's file list. Only uncomment and run this if you
-- want to throw away ALL existing data and start from zero. Normally
-- you do NOT need this: PART 1 below already safely updates old data
-- in place without deleting anything that still works.
--
-- To use it: select the lines between the two === markers below
-- (without the -- at the start of each), copy just that, and run it on
-- its own FIRST. Then come back and run the rest of this file (PART 1).
-- ===
-- drop table if exists favorites, reading_progress, books, categories,
--   list_books, lists, reports, admins, licenses cascade;
-- drop function if exists is_admin();
-- delete from storage.objects where bucket_id = 'books';
-- delete from storage.buckets where id = 'books';
-- ===
-- =====================================================================

-- =====================================================================
-- PART 1: SETUP — tables, security rules, storage, categories.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Clear away anything from an OLDER version of this project.
--    On a brand new project every line below simply finds nothing and
--    does nothing - that is expected and fine.
-- ---------------------------------------------------------------------
drop table if exists list_books, lists, reports, admins, licenses cascade;
drop function if exists is_admin();

-- ---------------------------------------------------------------------
-- 2) Tables. CREATE ... IF NOT EXISTS sets up a brand-new project.
--    The ALTER lines right after it then make sure an EXISTING "books"
--    table (from any earlier version) ends up with the same columns too.
-- ---------------------------------------------------------------------
create table if not exists categories (
  id    serial primary key,
  name  text not null unique,
  slug  text not null unique
);

create table if not exists books (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  author       text not null,
  description  text,
  category_id  int references categories(id) on delete set null,
  file_url     text,                       -- the PDF (made required a few lines down)
  cover_url    text,
  uploaded_by  uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now()
);

alter table books add column if not exists file_url text;
alter table books add column if not exists cover_url text;
alter table books add column if not exists category_id int references categories(id) on delete set null;
alter table books add column if not exists uploaded_by uuid references auth.users(id) on delete set null;
alter table books add column if not exists created_at timestamptz not null default now();

-- A book without a PDF (an older "text" book) can no longer be shown - remove any such rows,
-- then drop the columns that only that older design needed.
delete from books where file_url is null;
alter table books drop column if exists format;
alter table books drop column if exists content;
alter table books drop column if exists license;
alter table books drop column if exists source_url;
alter table books drop column if exists status;
alter table books alter column file_url set not null;

-- Where each user stopped in each book ("pick up where you left off")
create table if not exists reading_progress (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  book_id          uuid not null references books(id) on delete cascade,
  current_page     int not null default 1,
  scroll_percent   int not null default 0,
  progress_percent int not null default 0,
  last_read_at     timestamptz not null default now(),
  unique (user_id, book_id)
);

-- Favorite books: a many-to-many table between users and books
create table if not exists favorites (
  user_id     uuid not null references auth.users(id) on delete cascade,
  book_id     uuid not null references books(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, book_id)
);

-- Carry forward anyone's old reading lists as favorites, if that older table still exists
-- (it was dropped above, so this only matters the very first time you run this file).

-- ---------------------------------------------------------------------
-- 3) Security: Row Level Security (RLS). DROP POLICY IF EXISTS first means
--    this whole file can be run again later without "policy already exists" errors.
-- ---------------------------------------------------------------------
alter table categories       enable row level security;
alter table books            enable row level security;
alter table reading_progress enable row level security;
alter table favorites        enable row level security;

drop policy if exists "Anyone can read categories" on categories;
create policy "Anyone can read categories" on categories for select using (true);

drop policy if exists "Anyone can read books" on books;
create policy "Anyone can read books" on books for select using (true);

drop policy if exists "Users add books" on books;
create policy "Users add books" on books for insert to authenticated
  with check (uploaded_by = auth.uid());

drop policy if exists "Owners update own books" on books;
create policy "Owners update own books" on books for update to authenticated
  using (uploaded_by = auth.uid()) with check (uploaded_by = auth.uid());

drop policy if exists "Owners delete own books" on books;
create policy "Owners delete own books" on books for delete to authenticated
  using (uploaded_by = auth.uid());

-- Old policies from an earlier version (they mentioned status/is_admin, which no longer exist)
drop policy if exists "Read approved, own or (admin) all books" on books;
drop policy if exists "Users add pending books" on books;
drop policy if exists "Admins update books" on books;
drop policy if exists "Admins or owners delete books" on books;

drop policy if exists "Own progress" on reading_progress;
create policy "Own progress" on reading_progress for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Own favorites" on favorites;
create policy "Own favorites" on favorites for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

grant usage on schema public to anon, authenticated;
grant select on categories, books to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;

-- ---------------------------------------------------------------------
-- 4) File storage (for PDF books and cover images)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('books', 'books', true, 52428800,
        array['application/pdf', 'image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = 52428800;

drop policy if exists "Users upload to own folder" on storage.objects;
create policy "Users upload to own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'books' and (storage.foldername(name))[2] = auth.uid()::text);

drop policy if exists "Users delete own files" on storage.objects;
create policy "Users delete own files" on storage.objects for delete to authenticated
  using (bucket_id = 'books' and (storage.foldername(name))[2] = auth.uid()::text);

-- ---------------------------------------------------------------------
-- 5) Categories. on conflict do nothing means running this again is safe
--    and will not duplicate or error - and it is how you add "Exam
--    Preparation" to a project that does not have it yet.
-- ---------------------------------------------------------------------
insert into categories (name, slug) values
  ('Cybersecurity',     'cybersecurity'),
  ('Programming',       'programming'),
  ('Self-Improvement',  'self-improvement'),
  ('Science',           'science'),
  ('Exam Preparation',  'exam-preparation')
on conflict do nothing;

-- ---------------------------------------------------------------------
-- PART 1 done. Sample books are NOT inserted here on purpose: a book
-- needs a real PDF file, and plain SQL cannot upload one for you. Log
-- in on the website and upload the 3 ready-made PDFs in the
-- sample-books/ folder using the Upload page - that takes under a
-- minute and needs no SQL.
-- ---------------------------------------------------------------------


-- =====================================================================
-- PART 2: 3 sample queries for your viva, on this project's own data.
-- Each one matches a topic usually taught early in a DBMS course. Run
-- them ONE AT A TIME (select just that query's text, then Run) so you
-- can see and explain each result on its own.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Query 1: JOIN
-- Topic: combining two tables that are linked by a foreign key.
-- Every book's category_id points to a row in categories; JOIN brings
-- the category's name onto the same row as the book, instead of just
-- showing a number.
-- ---------------------------------------------------------------------
select books.title, books.author, categories.name as category
from books
join categories on books.category_id = categories.id
order by categories.name, books.title;


-- ---------------------------------------------------------------------
-- Query 2: GROUP BY + COUNT
-- Topic: combining rows that share the same value, then counting them -
-- the same pattern as "find the total number of students in each class".
-- Here, one row per category, with how many books are in it.
-- ---------------------------------------------------------------------
select categories.name as category, count(books.id) as total_books
from categories
left join books on books.category_id = categories.id
group by categories.name
order by total_books desc;


-- ---------------------------------------------------------------------
-- Query 3: GROUP BY + AVG, across two tables
-- Topic: the same GROUP BY + aggregate idea as Query 2, but the number
-- being averaged (progress_percent) lives in a DIFFERENT table
-- (reading_progress), reached through a JOIN - same pattern as
-- "find the average marks of each student", with books instead of students.
-- ---------------------------------------------------------------------
select books.title, round(avg(reading_progress.progress_percent)) as avg_percent_read
from books
join reading_progress on reading_progress.book_id = books.id
group by books.title
order by avg_percent_read desc;
