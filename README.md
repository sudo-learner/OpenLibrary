# OpenLibrary: Online Free Book Library (Database Project)

A simple free-book reading website built with **plain HTML, CSS and JavaScript** (no framework, no build step) and a **Supabase (PostgreSQL)** database.

Every book on this site is free for everyone to read. There is no licence check, no admin approval and no review step — a book appears in the library the moment it is uploaded. This keeps the project small and easy to explain, which is the goal of a class database project.

Features: browse, search and sort books, categories with picture tiles (including Exam Preparation), light/dark site theme, a smooth full-HD PDF reading page with swipe/tap navigation and a focus mode, "continue where you stopped", a dashboard, favorites, and PDF-only upload.

---

## 1. Folder structure

```
OpenLibrary-DB-Project/
├── index.html         Home page (search, book shelf, topics, latest books)
├── categories.html    Browse by category, search, sort
├── book.html          Book details, read button, favorite button
├── reader.html          Reading page (HD PDF, page preloading, swipe/tap, focus mode, saves progress)
├── dashboard.html      Reading statistics + my uploads
├── favorites.html      Books you saved
├── upload.html         Upload a book (title, author, category, file)
├── login.html          Log in / create account
├── favicon.svg         Site logo
├── images/             Home page pictures (hero, topic tiles, feature pictures)
├── css/style.css       All styling (light + dark theme, fonts)
├── js/
│   ├── config.js       <-- Supabase URL and key (already filled in this copy)
│   ├── common.js       Helper functions used by every page
│   ├── theme.js        Light / dark theme switch
│   └── home.js, categories.js, book.js, reader.js, dashboard.js,
│       favorites.js, upload.js, login.js   (one per page)
├── sample-books/        3 ready-made PDFs to upload after setup, so the library isn't empty
└── database/
    ├── setup.sql        The ONLY SQL file this project needs — tables, security rules,
    │                    categories, AND 3 ready-to-run viva queries, all in one file
    └── ER-diagram.md    The diagram from section 3, as a Mermaid file
```

Rule to remember: **one HTML page = one JS file** with the same name.

---

## 1b. The reading page, explained

Every book is a PDF, and the reader is built to avoid the two most common reading annoyances and to feel nice to use:

**No problems while reading**
- **Pages are ready before you tap Next.** The page next to the one you're on renders quietly in the background, so flipping forward feels instant instead of waiting for a spinner every time.
- **A resize or phone rotation never leaves the page blurry or the wrong size.** The reader notices and redraws the current page sharp again.
- **One broken page cannot break the whole book.** If a single page fails to render, only that page shows a "Retry" button — the rest of the book still works. If the PDF file itself cannot be reached (for example, no internet), the reader shows a clear message with its own Retry button instead of a blank screen.
- Full HD rendering: every page is drawn with at least 2x more pixels than the screen shows, so text stays sharp even on high-density phone and laptop screens (see also section on uploads below).

**Nicer to read**
- A soft crossfade between pages instead of a hard jump.
- **Swipe left/right** on a phone or tablet to turn pages.
- **Tap the edges** of the page (left = previous, right = next) — like a phone reading app. Tap the **middle** of the page (or press `F`) to enter **Focus mode**, which hides every toolbar so only the page is left; tap the middle again (or press `Escape`) to bring the toolbars back.
- Keyboard shortcuts: `→` / space = next page, `←` = previous, `Home` / `End` = first / last page.
- **Fits the screen by default** — a page opens showing its whole self on the device, no scrolling needed to see it all. From there you can zoom in with:
  - the **+ / −** buttons,
  - **Ctrl (or Cmd) + scroll wheel**, or a **touchpad pinch** (browsers report a trackpad pinch as a Ctrl-wheel event, so one thing in the code handles both),
  - a **two-finger pinch on a touchscreen**, with a live preview while your fingers move and one sharp HD re-render the moment you lift them.
  Once zoomed in, a one-finger drag pans around the page instead of turning it (page-turning by swipe only applies at the default fit size).
- A first-time hint reminds new readers that they can swipe or tap the sides.

---

## 1c. Uploads are PDF-only now

The old "paste the text" option is gone — every upload must be a **PDF file** (up to 50 MB). This keeps the project smaller (`books` no longer needs `format` or `content` columns) and means every book automatically gets the same full-HD reading experience:

- The file is stored exactly as uploaded — never compressed or resized.
- The reading page draws each page at a higher resolution than the screen, so it always looks sharp regardless of screen size.
- The **Download original PDF** button on a book's page always gives back the exact same file that was uploaded.

If a PDF still looks blurry, it was already low quality *before* it was uploaded (for example, a scanned photo of a page). Uploading the real, original PDF gives the best result.

---

## 1d. Three SQL queries for your viva

The bottom of `database/setup.sql` ("PART 2") has exactly 3 ready-to-run queries on this project's own data, each matching a topic usually taught early in a DBMS course:

1. **JOIN** — list every book with its category name (instead of just a `category_id` number).
2. **GROUP BY + COUNT** — how many books are in each category.
3. **GROUP BY + AVG, across two tables** — the average reading progress of each book, pulled from `reading_progress` through a JOIN.

Run them one at a time in Supabase's SQL Editor (select just one query's text, then Run) so you can see and explain each result on its own. Running the whole file at once also works for setup, but then Supabase only shows you the result of the last query (Query 3) — that's normal.

**Want to wipe all existing data and start completely fresh first?** `setup.sql` has a commented-out "DANGER ZONE" block near the top, right after the file's opening comment. Uncomment just those few lines (remove the `--` at the start of each), run that part on its own first, then run the rest of the file as usual. Only do this if you are sure you want to delete everything — PART 1 on its own already safely updates an older database without deleting anything that still works.

---

## 2. Setup (5 minutes)

1. Create a free project on <https://supabase.com>.
2. Open **SQL Editor -> New query**, paste the full content of `database/setup.sql`, click **Run**. This one file is all the SQL this project needs, whether your Supabase project is brand new or already has an older version of this project in it.
3. Open **Authentication -> Sign In / Providers -> Email** and turn **OFF** "Confirm email" (so sign-up works instantly in class).
4. `js/config.js` in this download is already filled with a working Supabase project, so you can run the site as it is. To use your **own** project instead, open `js/config.js` and replace the URL and key (found in Project Settings -> API, use the "anon public" key).
5. Run the site: in VS Code install **Live Server**, right-click `index.html` -> *Open with Live Server*.
6. **Populate the library:** create an account on the site, open **Upload**, and upload the 3 PDFs from the `sample-books/` folder (one at a time). That's it — no SQL needed for sample books, because a book always needs a real PDF file, and only the website can put a file into Storage correctly.

**Already set up and just want the new "Exam Preparation" category?** You do not need a separate query — `database/setup.sql` already includes it, and running the whole file again is always safe (nothing gets duplicated or broken). If it still does not appear after running it, see the troubleshooting note right after this list.

**Already used an older version of this project** (the 8-table version with licences/admin/lists, or a version that allowed plain-text books)? You still only need `database/setup.sql` — run that one file and it converts whatever you have into the current design by itself.

**A category (or anything else from the database) still does not show up on the site after running setup.sql?** Two things to check, in this order:
1. Open the Supabase **Table Editor** (not the SQL Editor) and look at the `categories` table directly — confirm the row is actually there. If it is not, the query did not run against the project you think it did, or it hit an error (scroll up in the SQL Editor's result pane to check).
2. Open `js/config.js` and compare its `SUPABASE_URL` to the URL of the project you just ran the query in (Project Settings -> API). If you have more than one Supabase project, it is easy to run SQL in one and have the website's keys point at another — then everything "works" but never shows the new data.
A hard refresh (Ctrl/Cmd + Shift + R) rules out the browser simply showing an old cached page.

**Free hosting:** push the folder to GitHub, then Settings -> Pages -> deploy from the main branch.

---

## 3. Database design (4 tables)

The full diagram is in `database/ER-diagram.md` (open it on GitHub or in VS Code with a Mermaid extension to see it drawn). In words:

```
auth.users (Supabase's own login table)
   │ 1                    │ 1                  │ 1
   ▼ many                 ▼ many               ▼ many
BOOKS ◄── CATEGORIES   READING_PROGRESS      FAVORITES
(uploaded_by FK)        (user_id, book_id,    (user_id, book_id)
                         page, percent)        <- many-to-many
```

| Table | Purpose | Important columns |
|---|---|---|
| `categories` | Book categories (Cybersecurity, Programming, Self-Improvement, Science, Exam Preparation) | name, slug |
| `books` | The library. Every book is public and is a PDF. | title, author, file_url (required), category_id (FK), uploaded_by (FK) |
| `reading_progress` | Where each user stopped | user_id, book_id, current_page, scroll_percent, progress_percent. `UNIQUE(user_id, book_id)` |
| `favorites` | Saved books (many-to-many) | user_id + book_id together are the primary key |

That is it — 4 tables. Compared to the earlier version, `licenses`, `reports`, `admins`, `lists` and `list_books` are gone, and `books` no longer has `license`, `source_url`, `status`, `format` or `content` — just a required `file_url` pointing at the PDF.

---

## 4. How each page talks to the database

| Page | What it does | Database action |
|---|---|---|
| Home | Latest books, topics, continue reading | `SELECT` from `books`; `SELECT` from `categories` |
| Categories | Filter, search, sort | `SELECT ... WHERE category_id = ? AND (title ILIKE ? OR author ILIKE ?) ORDER BY ...` |
| Book | Details, favorite | `SELECT` book; `INSERT`/`DELETE` in `favorites` |
| Reader | Saves your place | `UPSERT` into `reading_progress` |
| Dashboard | Statistics + delete own uploads | `SELECT` from `reading_progress` JOIN `books`; `DELETE` from `books` |
| Favorites | Your saved books | `SELECT` favorites JOIN `books`; `DELETE` |
| Upload | New book | Upload file to Storage, then `INSERT` into `books` |

Supabase query in JS reads like SQL:
```js
db.from("books").select("title, author").order("created_at", { ascending: false })
// = SELECT title, author FROM books ORDER BY created_at DESC
```

---

## 5. Security, without an admin

There is no admin or review step, but the database still protects people's own data with **Row Level Security**:

- Anyone (even logged out) can read every book and category.
- A logged-in user can only edit or delete **his own** uploaded books (`uploaded_by = auth.uid()`).
- `reading_progress` and `favorites` are private: a user can only see and change his own rows.

This is enough for a class project. It is not meant to police copyright — see section 7 for that.

---

## 6. Questions a teacher may ask

**Why Supabase?** It gives a real PostgreSQL database, login and file storage for free, callable directly from JavaScript.

**Is it safe to keep the key in JavaScript?** The `anon` key is public by design. Security comes from the Row Level Security rules in `setup.sql` — for example, `reading_progress` only allows `user_id = auth.uid()`, so no one can read another person's progress.

**Why is `favorites` a table with no `id` column?** Its primary key is the *pair* `(user_id, book_id)`. A user can never favorite the same book twice, and the database enforces that by itself — this is the standard way to model a many-to-many relationship.

**How is "continue where you stopped" done?** While reading, the page number and scroll percentage are saved (0.8 seconds after the last change) into `reading_progress`. When the book is opened again, they are loaded and restored.

**What stops a bad upload?** Nothing at the database level any more — this version trusts the uploader, which is why it is simpler. A user can only delete his own uploads (see section 5). If you want basic protection back, section 7 has 3 small ideas.

**How do you prevent XSS?** All user text goes through `escapeHtml()` before it is shown, and links are checked with `safeUrl()`.

**How does HD upload work?** See section 1c and 1b above: the file is never compressed, and the reader always draws pages at a higher resolution than the screen.

**Why remove the text-paste option?** Every book now goes through the exact same PDF pipeline: one rendering engine (PDF.js), one HD scaling rule, one download button. That is fewer code paths to explain and fewer things that can break — a good trade-off for a project you present in a viva.

---

## 7. Ideas if you want to add a feature back (optional, easy, in order of effort)

1. **A short "About this book" note instead of a licence.** Add one text column, `source_note`, to `books` (nullable, no rule enforced). Uploaders can optionally say where a book came from. Zero new tables.
2. **A simple report button, no admin panel.** Add one table, `reports (book_id, reason, created_at)`. Show a "Report" link on the book page that just inserts a row. You (the teacher / owner) read the table directly in Supabase — no `admin.html` needed.
3. **Ratings.** Add `ratings (user_id, book_id, stars)`, same many-to-many shape as `favorites`. Show an average with `AVG(stars) GROUP BY book_id`. Good if you want to demonstrate a `GROUP BY` query in your report.
4. **Comments.** One table, `comments (id, book_id, user_id, text, created_at)`. One-to-many from books and from users — a classic table to show in a viva.
5. **"Random book" button** on the home page — pure front-end, no new table: `ORDER BY random() LIMIT 1` in a Supabase query.

Pick at most one or two — the point of this version is to stay small enough to explain confidently in a few minutes.
