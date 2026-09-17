# Intro to Digital Media & Culture

Course materials for Intro to Digital Media & Culture, Emerson College, Fall 2026. The course site is at https://mroberts1.github.io/marlboro-digital-culture.

Course pages are in the `content/` folder. Everything else in this repo (repository) builds the website, and you can ignore it.

## Open the materials in Obsidian

1. Download the repo. Either:

   - clone it with git:
     ```
     git clone https://github.com/mroberts1/marlboro-digital-culture.git
     ```
   - or, without git, click Code > Download ZIP on the GitHub page and unzip it.

2. In Obsidian, choose "Open folder as vault" and select the `content` folder inside the downloaded folder. Select `content`, not the top-level folder.

## Updates

New materials are added during the semester. If you cloned the repo, run this command in a terminal inside the `marlboro-digital-culture` directory (you will need to use a terminal app):

```
git pull
```

Alternatively, if you originally downloaded the ZIP, you could just download it again.

Notes you write inside the vault can conflict with updates. Keep your own notes in a separate vault, or in a new folder the course doesn't use.

## Download only the course materials

If you use git and just want the course content without all the website files, clone this way instead:

```
git clone --filter=blob:none --sparse https://github.com/mroberts1/marlboro-digital-culture.git
cd marlboro-digital-culture
git sparse-checkout set content
```

For how the site is built, see [AGENTS.md](AGENTS.md).
