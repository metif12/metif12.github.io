module main

import markdown
import os

// A project case study loaded from content/projects/<slug>.md.
struct Project {
pub:
	title    string
	summary  string
	problem  string
	order    int
	status   string
	featured bool
	stack    []string
	repo     string
	demo     string
	started  string
	tags     []string
	slug     string
	html     string
}

struct Skill {
pub:
	name string
	note string
}

struct SkillGroup {
pub:
	domain string
	blurb  string
	skills []Skill
	proof  []string
}

fn strip_quotes(s string) string {
	t := s.trim_space()
	if t.len >= 2 {
		if (t.starts_with('"') && t.ends_with('"'))
			|| (t.starts_with("'") && t.ends_with("'")) {
			return t[1..t.len - 1]
		}
	}
	return t
}

// split_frontmatter separates the leading `---` YAML block from the body.
fn split_frontmatter(raw string) (string, string) {
	norm := raw.replace('\r\n', '\n')
	if !norm.starts_with('---\n') {
		panic('content: missing frontmatter fence')
	}
	rest := norm[4..]
	idx := rest.index('\n---\n') or { panic('content: unterminated frontmatter fence') }
	return rest[..idx], rest[idx + 5..]
}

// parse_fm parses the flat frontmatter used by project files:
// top-level `key: value` pairs, `>-` folded scalars whose continuation lines
// are indented, and `key:` followed by indented `- item` lists.
fn parse_fm(fm string) map[string][]string {
	mut m := map[string][]string{}
	mut key := ''
	mut folded := false
	for line in fm.split_into_lines() {
		if line.trim_space() == '' {
			continue
		}
		if line.starts_with(' ') || line.starts_with('\t') {
			t := line.trim_space()
			if t.starts_with('- ') {
				m[key] << strip_quotes(t[2..])
				folded = false
			} else if folded {
				if m[key].len == 0 {
					m[key] << t
				} else {
					m[key][0] += ' ' + t
				}
			}
			continue
		}
		idx := line.index(':') or { continue }
		key = line[..idx].trim_space()
		val := line[idx + 1..].trim_space()
		folded = false
		if val == '>-' || val == '>' || val == '|' {
			m[key] = ['>']
			folded = true
		} else if val == '' {
			m[key] = []string{}
		} else {
			m[key] = [strip_quotes(val)]
		}
	}
	// Unfold the placeholder: a folded scalar collected its lines into element 0.
	for k, v in m {
		if v.len == 1 && v[0] == '>' {
			m[k] = ['']
		}
	}
	return m
}

fn fm_str(m map[string][]string, key string) string {
	if key in m && m[key].len > 0 {
		return m[key][0]
	}
	return ''
}

fn fm_list(m map[string][]string, key string) []string {
	if key in m {
		return m[key].clone()
	}
	return []string{}
}

fn fm_bool(m map[string][]string, key string) bool {
	return fm_str(m, key) == 'true'
}

fn fm_int(m map[string][]string, key string) int {
	return fm_str(m, key).int()
}

// load_projects reads every content/projects/*.md file, validates the fields
// it needs, renders the body to HTML once, and returns projects ordered by
// `order`, then title.
fn load_projects(content_dir string) []Project {
	dir := os.join_path(content_dir, 'projects')
	files := os.ls(dir) or { panic('content: cannot list ${dir}: ${err}') }
	mut out := []Project{}
	for f in files {
		if !f.ends_with('.md') {
			continue
		}
		slug := f[..f.len - 3]
		raw := os.read_file(os.join_path(dir, f)) or { panic('content: cannot read ${f}: ${err}') }
		fm, body := split_frontmatter(raw)
		m := parse_fm(fm)
		title := fm_str(m, 'title')
		if title == '' {
			panic('content: ${f} has no title')
		}
		status := fm_str(m, 'status')
		out << Project{
			title:    title
			summary:  fm_str(m, 'summary')
			problem:  fm_str(m, 'problem')
			order:    fm_int(m, 'order')
			status:   if status == '' { 'live' } else { status }
			featured: fm_bool(m, 'featured')
			stack:    fm_list(m, 'stack')
			repo:     fm_str(m, 'repo')
			demo:     fm_str(m, 'demo')
			started:  fm_str(m, 'started')
			tags:     fm_list(m, 'tags')
			slug:     slug
			html:     markdown.to_html(body)
		}
	}
	out.sort_with_compare(fn (a &Project, b &Project) int {
		if a.order != b.order {
			return a.order - b.order
		}
		if a.title < b.title {
			return -1
		}
		if a.title > b.title {
			return 1
		}
		return 0
	})
	return out
}

fn count_indent(s string) int {
	mut n := 0
	for c in s {
		if c == ` ` {
			n++
		} else if c == `\t` {
			n += 2
		} else {
			break
		}
	}
	return n
}

// parse_skills reads content/skills.md: a YAML sequence of domain maps with
// folded blurbs/notes and `- item` proof lists. It is a small purpose-built
// parser for exactly that shape, not a general YAML reader.
fn parse_skills(raw string) []SkillGroup {
	mut groups := []SkillGroup{}
	mut started := false
	mut domain := ''
	mut blurb := ''
	mut skills := []Skill{}
	mut proof := []string{}
	mut skill_name := ''
	mut note := ''
	mut has_skill := false
	mut target := '' // folded-scalar sink: 'blurb', 'note', or ''
	for raw_line in raw.replace('\r\n', '\n').split_into_lines() {
		indent := count_indent(raw_line)
		t := raw_line.trim_space()
		if t == '' || t.starts_with('#') {
			continue
		}
		if indent == 0 && t.starts_with('- domain:') {
			if started {
				if has_skill {
					skills << Skill{skill_name, note}
				}
				groups << SkillGroup{domain, blurb, skills, proof}
			}
			started = true
			domain = strip_quotes(t['- domain:'.len..])
			blurb = ''
			skills = []Skill{}
			proof = []string{}
			skill_name = ''
			note = ''
			has_skill = false
			target = ''
			continue
		}
		if !started {
			continue
		}
		if indent == 2 {
			if t.starts_with('blurb:') {
				v := t['blurb:'.len..].trim_space()
				if v == '>-' || v == '>' || v == '|' {
					blurb = ''
					target = 'blurb'
				} else {
					blurb = strip_quotes(v)
					target = ''
				}
			} else {
				target = ''
			}
			continue
		}
		if indent == 4 && t.starts_with('- name:') {
			if has_skill {
				skills << Skill{skill_name, note}
			}
			skill_name = strip_quotes(t['- name:'.len..])
			note = ''
			has_skill = true
			target = ''
			continue
		}
		if indent == 4 && t.starts_with('- ') {
			if has_skill {
				skills << Skill{skill_name, note}
				has_skill = false
				skill_name = ''
				note = ''
			}
			proof << strip_quotes(t[2..])
			target = ''
			continue
		}
		if indent == 6 && t.starts_with('note:') {
			v := t['note:'.len..].trim_space()
			if v == '>-' || v == '>' || v == '|' {
				note = ''
				target = 'note'
			} else {
				note = strip_quotes(v)
				target = ''
			}
			continue
		}
		if target == 'blurb' {
			blurb += if blurb == '' { t } else { ' ' + t }
		} else if target == 'note' {
			note += if note == '' { t } else { ' ' + t }
		}
	}
	if started {
		if has_skill {
			skills << Skill{skill_name, note}
		}
		groups << SkillGroup{domain, blurb, skills, proof}
	}
	return groups
}

fn load_skills(content_dir string) []SkillGroup {
	path := os.join_path(content_dir, 'skills.md')
	raw := os.read_file(path) or { panic('content: cannot read skills.md: ${err}') }
	return parse_skills(raw)
}
