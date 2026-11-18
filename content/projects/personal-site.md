---
title: Personal site
summary: This site — a full-stack build with Markdown content in git, a validated content pipeline and no database anywhere.
problem: >-
  A portfolio site usually forces a choice: a static site that a non-developer
  cannot update, or a CMS that adds a database, a vendor and a monthly bill.
  I wanted neither. The requirement was simple and slightly unusual — write
  content in the same editor I already use, and never lose a version of it.
order: 2
status: live
featured: true
stack:
  - TanStack Start
  - React 19
  - TypeScript
  - Cloudflare Workers
  - Tailwind CSS
  - shadcn/ui
  - Zod
  - Shiki
repo: https://github.com/metif12/my-website
tags:
  - frontend
  - fullstack
---

## The constraint that decided everything

The site deploys to Cloudflare Workers, which has no filesystem. That one fact
decided the content architecture.

The obvious approach is a database and a read per request. The alternative here
is to bundle the content at build time with Vite's `import.meta.glob` and `?raw`,
then validate every file against a Zod schema.

The result is one code path that behaves the same on Workers, Node and Vercel,
and no database anywhere in the stack.

The cost is real: content only changes when you rebuild. For a site whose saves
are git commits, that is not a limitation — the deploy *is* the build.

## Git is the database

Content is Markdown with YAML frontmatter, one file per post and per project.
A database would have to reimplement what git already does for free:

- version history and a readable `git diff` on every change
- real rollback via `git revert`, not a soft-delete flag
- reviewable content in a pull request before it goes live
- `grep` across every post written so far

**Frontmatter is validated, not trusted.** Every field goes through a Zod schema,
so a typo in a date fails the build with the file path and the field named:

```
[content] invalid frontmatter in content/blog/example.md:
  - date: expected YYYY-MM-DD
  - summary: Required
```

## Rendering

Markdown is parsed at build time and highlighted with Shiki. The highlighting
happens during the build rather than shipping a highlighter to the browser, so
the output is static HTML with no client-side Markdown cost.

## What is deliberately absent

- **No database.** Content is files.
- **No client-side state library.** TanStack Query handles the one thing that
  genuinely needs it, and nothing else was added.
- **No CSS-in-JS.** Tailwind plus a small set of tokens.

Each was available and each was left out. The interesting decisions in a build
are the exclusions, and those are the ones nobody writes down.

## The admin panel is gone

This was written when the site had one, and the claim it made was that a
single-admin panel gets simple auth for free.

It was not worth keeping. Editing a Markdown file and committing is barely
slower than filling in a form, and it is the same thing I was already doing.
Worse, the panel was the only reason the worker held a GitHub token with
`contents:write` — a write credential on a public edge worker, held for the
lifetime of a feature used by one person.

Removing it deleted about a thousand lines, seven env secrets, and the whole
authentication question. The content pipeline is unchanged: it was always Git,
and now the code says so too.
