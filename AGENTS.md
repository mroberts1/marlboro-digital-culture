# AGENTS.md

Technical notes for agents working on this Obsidian vault, which is published as
a static site with Quartz 5. Human-facing orientation lives in `README.md`.

## Layout

```
./              Obsidian vault root (this is what Obsidian actually opens)
  content/      what Quartz builds from. Notes and their assets go here
  .quartz/      the Quartz 5 install, hidden from Obsidian
  public/       build output, gitignored, safe to delete
```

## Running it

Use the scripts, never `npx quartz`. The repo's own bin is not linked into
`node_modules/.bin`, so npx falls through to an unrelated `quartz` package on
the registry (v0.0.1, a transmission-daemon client).

| Task            | Command                             |
| --------------- | ----------------------------------- |
| Serve with HMR  | `./dev.sh` (8080, ws 3003)          |
| Build to public | `./build.sh`                        |
| Override ports  | `PORT=8081 WS_PORT=3004 ./dev.sh`   |

Both scripts work from any directory.

## Gotchas that cost real time

These are verified against this vault, not guesses. Check them before
diagnosing anything else.

Everything the site serves must live under `content/`. Quartz only globs the
directory passed via `-d`. A file above it is never copied to `public/`, and a
`../` path does not escape: Quartz normalises it away, so `../img/x.jpg` emits
as `src="././img/x.jpg"` and 404s. Subdirectories at any depth are fine, and
the folder name does not matter. `content/img/` is the convention here.

`build.sh` and `dev.sh` cannot run at the same time. Both use `../public` as
the output directory, and a build starts by wiping it:
`Cleaned output directory ../public`. The dev server serves straight out of
that directory, so every URL 404s while a concurrent build runs, and a page
404s until the build re-emits it. This looks exactly like a missing or broken
page, and a browser will happily cache the 404 afterwards, so it outlives the
build that caused it. Stop the dev server before building, and hard-reload if
a page 404s once.

Adding a new asset file needs a server restart. The incremental rebuild picks
up markdown edits but does not copy newly added non-markdown files. The symptom
is an `<img>` that renders while the file itself 404s. Restart `./dev.sh` and
it is copied. Editing markdown afterwards hot reloads normally.

A YAML frontmatter error kills the whole dev server, not just the page. It
prints `Failed to process markdown` and the process exits, so the port goes
dead. Body-text errors do not do this, only frontmatter. Before investigating
hot reload, check the server is still alive:
`lsof -nP -iTCP:8080 -sTCP:LISTEN`. The recurring trigger is an unquoted colon
in a title, which YAML reads as a nested mapping. Quote it:
`title: "IN 206: Introduction to Digital Media & Culture"`.

The hot-reload client never reconnects. Quartz emits
`new WebSocket("ws://localhost:3003").addEventListener("message", () => location.reload(true))`
with no `onclose` handler. Any tab open across a server restart or crash holds a
dead socket forever, rebuilds correctly server-side, and never refreshes. Always
hard-reload the page after restarting the server.

Deleting a file while the server runs can poison the rebuild. The pending delete
is retried on every subsequent rebuild and fails with
`ENOENT: no such file or directory, unlink '../public/...'`, which blocks all
further rebuilds. Restart to clear it. Relevant when cleaning up scratch files.

Never run `build.sh` while `dev.sh` is running. Both write to `public/` and
`build.sh` cleans it first, which deletes the files the dev server is serving
and poisons its rebuild loop. The symptom is a server that still answers 200
with stale content but silently stops picking up edits. Restart to clear it.
Since CI builds on push, `build.sh` is rarely needed locally at all.

Obsidian's vault root is the project root, not `content/`. The template README
says to point Obsidian at `content/`, but `.obsidian/` sits at the root in this
vault, so that is not what happened. Consequence: in the sidebar `content` is
just one folder among others, and anything created at the top level lands beside
it rather than inside it, where Quartz cannot see it. There is no
`attachmentFolderPath` in `.obsidian/app.json`, so pasted images default to the
vault root and will 404. Setting it to `content/img` fixes that at the source.

## Authoring

Images. Standard markdown works but has no width control. Use the wikilink form
to size, where the number is pixels and height stays auto:

```markdown
![[img/photo.jpg|500]]
![[img/photo.jpg|500x300]]
```

`![[x.avif]]` renders as a transclude link, not an image, because the wikilink
embed does not recognise `.avif`. Convert with
`sips -s format jpeg img/x.avif --out img/x.jpg`.

Callouts. All 13 Obsidian types render, plus a 14th `custom` defined by this
theme. A blank line ends a callout, there is no closing marker; use a bare `>`
for a blank line inside one. Append `-` to start collapsed, `+` for expanded but
foldable.

```markdown
> [!custom] An explicit title
> Body.
>
> Second paragraph, same box.
```

Always give `[!custom]` a title. With none, Quartz falls back to the capitalised
type name and the header reads "Custom". An empty title and `&nbsp;` both fall
back too; only a literal zero-width space renders blank, which is not worth the
invisible character. To drop the header entirely, hide
`.callout[data-callout="custom"] > .callout-title` in `custom.scss`, accepting
that it removes the icon and titles from every custom callout.

YouTube. An image embed pointed at a watch URL becomes an iframe:

```markdown
![](https://www.youtube.com/watch?v=VIDEO_ID)
```

The iframe is a fixed `width="600px"` with no aspect-ratio rule, so it does not
scale on narrow screens. No responsive CSS exists for it yet in any vault here.

## Configuration

Prefer `.quartz/quartz.config.yaml` over patching vendored Quartz source, since
config survives an upgrade. Sidebar component labels take a `title` option:

```yaml
  - source: "@quartz-community/explorer"
    enabled: true
    options:
      title: Pages
```

Note that the explorer's mobile toggle `aria-label` is hardcoded in the compiled
plugin under `node_modules` and is not reachable from config or from the i18n
strings in `.quartz/quartz/i18n/locales/en-US.ts`.

Everything the YAML cannot express lives in `.quartz/quartz/styles/custom.scss`:
the self-hosted font, a tighter heading scale, wrapped code blocks, a card grid
for folder listings, and the `[!custom]` callout.

Helvetica Neue is the header, body and code face, set in `quartz.config.yaml`
with `fontOrigin: local` because it is a system face rather than a Google font.
The fallback stack for machines without it lives in `custom.scss`, which is
unlayered and so outranks the bare family the quartz-fonts plugin emits. That
plugin also hard-sets `h1..h6` unlayered, from a stylesheet loaded after
`custom.scss`, so the heading override there is prefixed with `body` to win on
specificity rather than source order.

`og-image` is disabled as a consequence: it fetches the `theme.typography`
families from Google Fonts to draw social cards and aborts the build with "No
fonts are loaded" when it cannot find them. Re-enabling it means going back to a
Google-served family.

The Departure Mono `@font-face` and its font files are kept but unreferenced, so
switching back is a config change alone. Its paths are relative, not
root-absolute, and must stay that way if it is ever re-enabled.

## Plugins installed from git

`quartz-image-zoom` (click an image to open it in a lightbox) is installed from
`github:vazome/quartz-image-zoom`, pinned in `.quartz/quartz.lock.json`. It adds
`class="lightbox-image"` to every content image; nothing is needed per-image.

Install with the bootstrap CLI, not npx:
`node ./quartz/bootstrap-cli.mjs plugin add github:<owner>/<repo>` from
`.quartz/`. The CLI re-serializes `quartz.config.yaml` and drops every comment
in it, so diff the config afterwards and restore them.

Git plugins install to `.quartz/.quartz/plugins/`, not `.quartz/plugins/`. The
loader joins `process.cwd()` with `.quartz/plugins` and the CLI already runs
from `.quartz/`, so the path doubles up. That directory is gitignored as a
cache, and `bootstrap-cli.mjs build` does not fetch missing plugins, so any
build path that calls the CLI directly must run `npm run install-plugins`
first. Dropping that step yields a green build with the plugin silently
missing.

## The wordcloud

`content/img/wordcloud.png` is generated from the bullet list on
`content/dystopian-zeitgeist.md`. Edit the terms, then regenerate:

    python3 script/wordcloud

It is not automatic and nothing in the build checks it, so an edited term list
with a stale image is the easy mistake: the page then shows words that are no
longer in the list. Commit both together.

Needs `pip install wordcloud`, plus Departure Mono as an `.otf` in
`~/Library/Fonts`. The repo only ships the woff/woff2 the site loads, and
Pillow cannot read those.

Terms are weighted equally, so the whole layout reflows whenever the set
changes. `random_state=42` makes a *given* set reproducible; it does not hold
the layout steady across edits. Expect the image to look rearranged after
adding a single word.

## Publishing to Canvas

`script/canvas` renders `content/index.md` and pushes it to the Canvas course.
Canvas is an output, like the Pages site and the PDF; the vault is the source.
Editing the generated syllabus or homepage in the Canvas UI works, but the
next push overwrites it.

    script/canvas syllabus   index.md to syllabus_body
    script/canvas pages      the content pages listed in canvas.json
    script/canvas home       front page: cover table plus a nav line
    script/canvas all        all three
    --print                  write the HTML locally, push nothing
    --publish                publish content pages instead of leaving drafts

Readings are listed in both `index.md` and the week pages. When pushing a week
page, check whether `index.md` changed too, and if so push `syllabus` as well.

Course id, site url, page list and cover image live in `canvas.json`.
A page's `source` is the Quartz slug, which is lowercased: `rur-intro` for
`RUR-intro.md`. A mismatch prints `SKIPPED (no content/X.md)` even though the file exists.
Generated `canvas-*.html` files are build artifacts and gitignored.

Emerson does not let instructors mint API tokens, so there is no token to use.
Auth is the logged-in browser session driven through `agent-browser`: Canvas's
own `/api/v1` endpoints accept the session cookie, with the `_csrf_token`
cookie sent back as an `X-CSRF-Token` header on writes. Log in once with
`agent-browser open --headed https://canvas.emerson.edu`, which prompts Duo.

Things that cost time to find, each established by testing rather than docs:

Canvas's sanitiser strips `<script>`, inline `<svg>`, `<link>` and HTML
comments, and keeps `<i>`, `<img>`, and `<div>` with id/class/data attributes.
So the click-to-play cover becomes its poster image, Font Awesome icons become
text labels, and a Font Awesome kit cannot work in Canvas at all: both the kit
script and the stylesheet link are stripped, leaving an empty `<i>`.

Look pages up by title, never by slug. Canvas derives the slug from the title,
so a guessed slug 404s, falls through to a create, and leaves a duplicate
page named `-2` on every push.
Changing a page's `title` in `canvas.json` therefore creates a second page and
orphans the original, which stays until it is deleted by hand.

`fetch()` is origin-relative, so the browser has to be on Canvas before the
script evaluates anything. Otherwise it silently talks to whatever page was
last open and reports "not logged in".

Relative URLs are absolutised against the Pages site, since `./img/x.png`
would otherwise resolve against canvas.emerson.edu.

Take a backup before any overwrite. They go in
`~/.claude/canvas-backups/<course id>-<timestamp>/`.

`digital-culture-fa26` and `lang-media-arts` get the same workflow and the
same design, so this vault is the reference to copy from rather than a
one-off. The shape is: home is a 50/50 table, cover and caption left, course
details right, followed by a nav line of `Syllabus | <content pages>`, with
`default_view` set to `wiki`. The full syllabus stays on Canvas's own Syllabus
page, keeping the same table at the top, because Canvas appends the course
summary below `syllabus_body`. Each `content/*.md` becomes one Canvas page.
Copying means `script/canvas` plus `canvas.json` with a new course id, site
url and page list.

## Scanned readings and copyright

Course reading PDFs are third-party scans. They belong in Canvas Files, which
is behind institutional login, not on the public Pages site. Own work such as
the syllabus is fine to publish either place. `digital-culture-fa26` and
`fsu-interactive-media-fa26` already exclude readings from git for this
reason; keep that split when adding PDFs here.

## Keeping this file current

Update this file when a change invalidates something above, or when a new
non-obvious behaviour costs time to diagnose. Record the symptom alongside the
cause: most entries here presented as a different problem than they were.

## Deployment

The site publishes to GitHub Pages from `main` via `.github/workflows/deploy.yml`:
`npm ci` in `.quartz/`, then the same build command as `build.sh`, then
`upload-pages-artifact` on `public/`. Pushing to `main` is the whole deploy
step; there is nothing to run locally first.

Live at https://mroberts1.github.io/marlboro-digital-culture/

`.quartz/` is vendored, not a git clone. Its own `.git` was removed so the
outer repo could track the files, so `git pull` from upstream Quartz is not
available. It sits at `jackyzha0/quartz` branch `v5`, commit
`075afd3f712da0088a07f5284a7b3aba37dd61b6`. To upgrade, clone that repo fresh
and reapply the local changes, which are `quartz.config.yaml`, `.node-version`,
`quartz/styles/custom.scss`, and `quartz/static/fonts/`.

`baseUrl` is `mroberts1.github.io/marlboro-digital-culture`, including the
subpath, because Pages serves this repo under a path rather than at a domain
root. Dropping the subpath breaks every generated link.

The `@quartz-community/cname` plugin is disabled. It writes `public/CNAME` from
`baseUrl`, and any CNAME file makes Pages try to serve a custom domain, which
fails on a `github.io` subpath. Re-enable it only alongside a real domain.

`.obsidian/` is gitignored. Plugin `data.json` files hold live credentials, and
one plugin ships a 59MB binary. The site build never reads it.
