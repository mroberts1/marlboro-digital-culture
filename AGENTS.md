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

Departure Mono is not on Google Fonts. Every build logs
`Google Fonts returned HTTP 400 for Departure Mono`. This is expected and
harmless; the `@font-face` in `custom.scss` is what actually loads it. Pinning
`weights: [400]` in the config stops the request asking for a weight that does
not exist anywhere, but does not silence the warning.

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

## The snapshot wordcloud

`content/img/wordcloud.png` is generated from the bullet list on
`content/snapshot.md`. Edit the terms, then regenerate:

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
