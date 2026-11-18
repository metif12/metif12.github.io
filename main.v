module main

import os
import veb

// App serves the same pages the static build emits, for local preview.
// Our context struct must embed `veb.Context`.
pub struct Context {
	veb.Context
}

pub struct App {
	veb.Controller
	veb.StaticHandler
pub mut:
	projects []Project
	skills   []SkillGroup
}

@['/'; get]
pub fn (app &App) index(mut ctx Context) veb.Result {
	return ctx.html(render_home(app.projects))
}

@['/projects'; get]
pub fn (app &App) projects(mut ctx Context) veb.Result {
	return ctx.html(render_projects(app.projects))
}

@['/projects/:slug'; get]
pub fn (app &App) project(mut ctx Context, slug string) veb.Result {
	for p in app.projects {
		if p.slug == slug {
			return ctx.html(render_project(p))
		}
	}
	return ctx.not_found()
}

@['/skills'; get]
pub fn (app &App) skills(mut ctx Context) veb.Result {
	return ctx.html(render_skills(app.skills, app.projects))
}

@['/contact'; get]
pub fn (app &App) contact(mut ctx Context) veb.Result {
	return ctx.html(render_contact())
}

@['/sitemap.xml'; get]
pub fn (app &App) sitemap(mut ctx Context) veb.Result {
	return ctx.text(render_sitemap(app.projects))
}

fn copy_dir(src string, dst string) {
	os.mkdir_all(dst) or { panic('build: cannot create ${dst}: ${err}') }
	for f in os.ls(src) or { panic('build: cannot list ${src}: ${err}') } {
		s := os.join_path(src, f)
		d := os.join_path(dst, f)
		if os.is_dir(s) {
			copy_dir(s, d)
		} else {
			os.cp(s, d) or { panic('build: cannot copy ${s}: ${err}') }
		}
	}
}

fn write_page(out string, path string, content string) {
	full := os.join_path(out, path)
	os.mkdir_all(os.dir(full)) or { panic('build: cannot create ${os.dir(full)}: ${err}') }
	os.write_file(full, content) or { panic('build: cannot write ${full}: ${err}') }
}

// build_site writes the whole static site into out/:
// one directory with index.html per route (clean URLs), the sitemap,
// the static assets, and the .nojekyll marker Pages needs.
fn build_site(out string, projects []Project, skills []SkillGroup) {
	write_page(out, 'index.html', render_home(projects))
	write_page(out, os.join_path('projects', 'index.html'), render_projects(projects))
	for p in projects {
		write_page(out, os.join_path('projects', p.slug, 'index.html'), render_project(p))
	}
	write_page(out, os.join_path('skills', 'index.html'), render_skills(skills, projects))
	write_page(out, os.join_path('contact', 'index.html'), render_contact())
	write_page(out, '404.html', render_404())
	write_page(out, 'sitemap.xml', render_sitemap(projects))
	copy_dir('static', out)
	os.write_file(os.join_path(out, '.nojekyll'), '') or {
		panic('build: cannot write .nojekyll: ${err}')
	}
	println('built ${projects.len} projects + resume pages into ${out}/')
}

fn main() {
	projects := load_projects('content')
	skills := load_skills('content')
	if os.args.len > 1 && os.args[1] == 'build' {
		out := if os.args.len > 2 { os.args[2] } else { 'dist' }
		build_site(out, projects, skills)
		return
	}
	port := if os.args.len > 2 { os.args[2].int() } else { 8080 }
	mut app := &App{
		projects: projects
		skills:   skills
	}
	// Static assets (style.css, photos, favicons, robots.txt) at root URLs.
	app.handle_static('static', true) or { panic('preview: ${err}') }
	println('preview at http://localhost:${port}  (v run . build dist  for the static build)')
	veb.run[App, Context](mut app, port)
}
