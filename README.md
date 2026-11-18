# mahdir-pages

Resume + projects site for mahdir.ir, built with **V** and previewed with
**veb**, deployed as a static site on **GitHub Pages**. No blog, no admin,
no database, no JavaScript framework — markdown in, HTML out.

Ported from the Cloudflare Worker + TanStack Start version: same content
(`content/` is copied from it), same routes minus `/blog`, one small
hand-written stylesheet instead of Tailwind.

## Layout

- `main.v` — entry point. `v run . build [dir]` writes the static site,
  `v run . serve [port]` previews the same pages with veb.
- `content.v` — loads `content/projects/*.md` and `content/skills.md`,
  renders markdown bodies to HTML with stdlib `markdown`.
- `pages.v` — HTML shell + one renderer per route.
- `content/` — markdown source. Edit here, rebuild, push.
- `static/` — copied verbatim into the output: `style.css`, photos,
  favicons, `robots.txt`, `manifest.json`.
- `.github/workflows/deploy.yml` — builds with V 0.5.2 and deploys to Pages.

## Commands

```sh
v run . build dist   # static build into dist/
v run . serve        # preview at http://localhost:8080
v run . serve 8123   # preview on another port
v fmt -w .           # format
```

## Deploy to GitHub Pages

1. Create the repo `metif12.github.io` (user site = serves at the root,
   which is what `site_url` in `pages.v` assumes).
2. Push this directory to `main`.
3. Repo **Settings → Pages → Build and deployment → Source: GitHub Actions**.
4. Push to `main` — the workflow builds and deploys. First run takes a few
   minutes for V to install.

Optional custom domain: keep `mahdir.ir` by adding a `CNAME` file containing
`mahdir.ir` in `static/`, then point DNS at GitHub Pages and tick
**Enforce HTTPS** in the Pages settings.

## Editing

- New project: add `content/projects/<slug>.md` with the same frontmatter
  (`title summary problem order status featured stack repo demo started tags`),
  rebuild. `order` controls listing order; `featured: true` pins it on home.
- Skills: `content/skills.md`, one `- domain:` block per group.
- The contact channels and "Currently" bullets live in `pages.v`
  (`render_contact`, `render_home`) — edit them there.
