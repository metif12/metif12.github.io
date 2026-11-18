module main

import time

const site_url = 'https://metif12.github.io'
const site_name = 'Mahdi Ramezaan Zaade'
const site_role = 'Full-stack developer'
const site_email = 'info@mahdir.ir'
const site_location = 'Iran'
const github_url = 'https://github.com/metif12'
const linkedin_url = 'https://www.linkedin.com/in/metif12/'

fn esc(s string) string {
	return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"',
		'&quot;')
}

fn nav_html(active string) string {
	items := [
		['/', 'About'],
		['/projects', 'Projects'],
		['/skills', 'Skills'],
		['/contact', 'Contact'],
	]
	mut out := '<nav>'
	for it in items {
		cls := if it[0] == active { ' class="active"' } else { '' }
		out += '<a href="${it[0]}"${cls}>${it[1]}</a>'
	}
	out += '</nav>'
	return out
}

// layout wraps page content in the full document shell.
fn layout(page_title string, description string, path string, active string, body string) string {
	desc := if description == '' {
		'Full-stack developer working in TypeScript, Go and V.'
	} else {
		description
	}
	return '<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(page_title)}</title>
<meta name="description" content="${esc(desc)}">
<meta name="author" content="${site_name}">
<meta name="theme-color" content="#020617">
<meta property="og:type" content="website">
<meta property="og:site_name" content="${site_name}">
<meta property="og:title" content="${esc(page_title)}">
<meta property="og:description" content="${esc(desc)}">
<meta property="og:url" content="${site_url}${path}">
<meta property="og:image" content="${site_url}/og.webp">
<link rel="stylesheet" href="/style.css">
<link rel="icon" type="image/svg+xml" href="/fav/favicon.svg">
<link rel="icon" type="image/png" href="/fav/favicon-96x96.png" sizes="96x96">
<link rel="apple-touch-icon" href="/fav/apple-touch-icon.png">
<link rel="manifest" href="/manifest.json">
<link rel="canonical" href="${site_url}${path}">
</head>
<body>
<div class="wrap">
<header class="site-head">
<a class="brand" href="/"><img src="/me-256.webp" alt="${site_name}" width="48" height="48"><span><strong>${site_name}</strong><small>${site_role}</small></span></a>
${nav_html(active)}
</header>
<main>
${body}
</main>
<footer class="site-foot">&copy; ${time.now().year} ${site_name} &middot; <a href="${github_url}">GitHub</a></footer>
</div>
</body>
</html>
'
}

fn tag_html(t string) string {
	return '<span class="tag">${esc(t)}</span>'
}

fn project_card(p Project) string {
	mut badge := ''
	if p.status != 'live' {
		badge = ' <span class="badge">${esc(p.status)}</span>'
	}
	mut stack := ''
	if p.stack.len > 0 {
		stack = ' <span class="mono dim">${esc(p.stack[0])}</span>'
	}
	return '<li><a class="card" href="/projects/${p.slug}"><div class="card-top"><h3>${esc(p.title)}</h3>${stack}</div><p>${esc(p.summary)}</p>${badge}</a></li>'
}

fn render_home(projects []Project) string {
	mut featured := ''
	for p in projects {
		if p.featured {
			featured += project_card(p)
		}
	}
	body := '<section class="hero">
<p class="kicker mono">${site_location}</p>
<h1>Hi, I\'m Mahdi.</h1>
<p class="lede">I\'m a full-stack developer working in <strong>TypeScript</strong>, <strong>Go</strong> and <strong>V</strong>. Most of what I find interesting sits in the boundary &mdash; between a framework and the code built on it, between a service and whoever calls it.</p>
<div class="row"><a class="btn" href="/projects">See my work</a><a class="btn ghost" href="mailto:${site_email}">Get in touch</a></div>
</section>
<section>
<div class="sec-head"><h2>Selected work</h2><a class="dim" href="/projects">All projects &rarr;</a></div>
<ul class="cards">${featured}</ul>
</section>
<section>
<h2>Currently</h2>
<ul class="bullets dim">
<li>Building Fluxget, an aria2 download manager in V.</li>
<li>Learning V properly instead of skimming the docs.</li>
<li>Open to contract work &mdash; documentation, small features, and API work.</li>
</ul>
</section>
<section>
<h2>Stack</h2>
<div class="tags"><span class="tag">TypeScript</span><span class="tag">React</span><span class="tag">Go</span><span class="tag">V</span><span class="tag">Postgres</span><span class="tag">Tailwind CSS</span></div>
</section>'
	return layout('${site_name} — ${site_role}', '', '/', '/', body)
}

fn render_projects(projects []Project) string {
	mut cards := ''
	for p in projects {
		mut badge := ''
		if p.status != 'live' {
			badge = ' <span class="badge">${esc(p.status)}</span>'
		}
		mut stack := ''
		for s in p.stack {
			stack += tag_html(s)
		}
		cards += '<li><a class="card" href="/projects/${p.slug}"><div class="card-top"><h2>${esc(p.title)}</h2>${badge}</div><p>${esc(p.summary)}</p><div class="tags">${stack}</div></a></li>'
	}
	body := '<h1>Projects</h1>
<p class="lede">Case studies, not screenshots. Each one covers the problem, the structure, and the decisions that were not obvious.</p>
<ul class="cards">${cards}</ul>
<p class="dim small">Older work &mdash; the information retrieval and clustering projects from university, plus a lot of PHP and Laravel from 2021 &mdash; is on <a href="${github_url}">GitHub</a>.</p>'
	return layout('Projects — ${site_name}', 'Case studies of systems I have built: what problem each one solves and where the interesting decisions are.',
		'/projects', '/projects', body)
}

fn render_project(p Project) string {
	mut meta := ''
	if p.status != '' {
		meta += '<span class="tag">${esc(p.status)}</span>'
	}
	if p.started != '' {
		meta += '<span class="tag mono">${esc(p.started)}</span>'
	}
	for s in p.stack {
		meta += tag_html(s)
	}
	mut links := ''
	if p.repo != '' {
		links += '<a class="btn ghost" href="${esc(p.repo)}">Repository</a>'
	}
	if p.demo != '' {
		links += '<a class="btn ghost" href="${esc(p.demo)}">Live demo</a>'
	}
	mut problem := ''
	if p.problem != '' {
		problem = '<blockquote class="problem">${esc(p.problem)}</blockquote>'
	}
	body := '<p><a class="dim" href="/projects">&larr; Projects</a></p>
<h1>${esc(p.title)}</h1>
<p class="lede">${esc(p.summary)}</p>
<div class="tags">${meta}</div>
<div class="row">${links}</div>
${problem}
<div class="prose">${p.html}</div>'
	return layout('${p.title} — ${site_name}', p.summary, '/projects/${p.slug}',
		'/projects', body)
}

fn render_skills(groups []SkillGroup, projects []Project) string {
	mut by_slug := map[string]string{}
	for p in projects {
		by_slug[p.slug] = p.title
	}
	mut secs := ''
	for g in groups {
		mut rows := ''
		for s in g.skills {
			rows += '<div class="skill"><dt class="mono">${esc(s.name)}</dt><dd>${esc(s.note)}</dd></div>'
		}
		mut proof := ''
		for slug in g.proof {
			title := by_slug[slug]
			if title != '' {
				proof += '<a class="tag link" href="/projects/${slug}">${esc(title)}</a>'
			}
		}
		if proof != '' {
			proof = '<div class="proof"><span class="dim small">See:</span> ${proof}</div>'
		}
		secs += '<section class="group"><h2>${esc(g.domain)}</h2><p class="dim">${esc(g.blurb)}</p><dl>${rows}</dl>${proof}</section>'
	}
	body := '<h1>Skills</h1>
<p class="lede">Grouped by domain rather than listed as forty badges. Every group links to the project that demonstrates it, because a claim without evidence is just a claim.</p>
${secs}'
	return layout('Skills — ${site_name}', 'Skills grouped by domain, each one linked to the project that demonstrates it.',
		'/skills', '/skills', body)
}

fn render_contact() string {
	channels := [
		['mailto:${site_email}', site_email, 'Email'],
		[github_url, 'github.com/metif12', 'GitHub'],
		[linkedin_url, 'LinkedIn', 'LinkedIn'],
	]
	mut rows := ''
	for c in channels {
		rows += '<li><a class="channel" href="${c[0]}"><span class="mono">${esc(c[1])}</span><span class="dim small">${c[2]}</span></a></li>'
	}
	body := '<h1>Contact</h1>
<p class="lede">I take contract work: technical documentation, small features and bug fixes, and API work. I reply to everything.</p>
<ul class="channels">${rows}</ul>
<section>
<h2 class="mono small dim caps">Good fit</h2>
<ul class="bullets dim">
<li>Documentation that is costing you signups.</li>
<li>A small feature or a bug fix in TypeScript, Go or React.</li>
<li>Backend work: endpoints, auth, schema, migrations.</li>
</ul>
<p class="dim">I work on small, clearly scoped things and give a fixed price before starting. Based in ${site_location}, working with clients across time zones.</p>
</section>'
	return layout('Contact — ${site_name}', 'Get in touch about contract work, or find me on GitHub and LinkedIn.',
		'/contact', '/contact', body)
}

fn render_404() string {
	body := '<h1>Not found</h1><p class="lede">That page does not exist. <a href="/">Back home</a>.</p>'
	return layout('Not found — ${site_name}', '', '/404', '', body)
}

fn render_sitemap(projects []Project) string {
	mut urls := ['/', '/projects', '/skills', '/contact']
	for p in projects {
		urls << '/projects/${p.slug}'
	}
	mut out := '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
	for u in urls {
		out += '  <url><loc>${site_url}${u}</loc><changefreq>weekly</changefreq></url>\n'
	}
	out += '</urlset>\n'
	return out
}
