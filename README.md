# IN 206: Introduction to Digital Media & Culture

Course materials for IN 206: Introduction to Digital Media & Culture, Emerson College, Fall 2026. The course site is at https://mroberts1.github.io/marlboro-digital-culture.

The syllabus and enrolled-student resources are on Canvas: https://canvas.emerson.edu/courses/2196805 (Emerson login required). A PDF copy of the syllabus is also in this repo at [`content/pdf/syllabus.pdf`](content/pdf/syllabus.pdf), though it may lag behind the live course site.

Course pages are in the `content/` folder. Everything else in this repo (repository) builds the website, and you can ignore it.

## Open the materials in Obsidian

1. Download the repo. Either:

   - clone it with git:
     ```
     git clone https://github.com/mroberts1/marlboro-digital-culture.git
     ```
   - or, without git, click Code > Download ZIP on the GitHub page and unzip it.

2. In Obsidian, choose "Open folder as vault" and select the downloaded `marlboro-digital-culture` folder itself, not the `content` folder inside it. Course pages then show up under `content` in the sidebar, alongside the site's other folders.

## Updates

New materials are added during the semester. If you cloned the repo, run this command in a terminal inside the `marlboro-digital-culture` directory (you will need to use a terminal app):

```
git pull
```

Alternatively, if you originally downloaded the ZIP, you could just download it again.

Notes you write inside the vault can conflict with updates. Keep your own notes in a separate vault, or in a new folder the course doesn't use. If you paste in images, set Obsidian's attachment folder to `content/img` (Settings > Files and links) so they save alongside the course pages instead of the vault root.

## Download only the course materials

If you use git and just want the course content without all the website files, clone this way instead:

```
git clone --filter=blob:none --sparse https://github.com/mroberts1/marlboro-digital-culture.git
cd marlboro-digital-culture
git sparse-checkout set content
```

## Preview the site locally

If you have Node.js installed, `./dev.sh` serves the site locally with hot reload (see [AGENTS.md](AGENTS.md) for details, ports, and how the site is built).
