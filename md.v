module main

// md_to_html renders the Markdown subset this site's content actually uses:
// ATX headings, paragraphs, fenced code blocks, blockquotes, flat
// unordered/ordered lists, pipe tables, thematic breaks, and inline `code`,
// **bold**, *italic*, [text](url) and ![alt](src).
//
// It exists so the static build has no stdlib-version dependency: the
// `markdown` module is not in every V release, and content rendering must
// work on the pinned CI compiler, not just the machine that wrote it.

fn md_escape(s string) string {
	return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"',
		'&quot;')
}

// md_inline renders inline markup. Code spans are scanned first so nothing
// inside backticks is treated as markup; emphasis and links recurse so
// **bold with `code` inside** works.
fn md_inline(s string) string {
	mut out := ''
	mut i := 0
	for i < s.len {
		c := s[i]
		if c == `\\` && i + 1 < s.len {
			n := s[i + 1]
			if n == 96 || n == `*` || n == `_` || n == `[` || n == `]` || n == `!` {
				out += md_escape(s[i + 1..i + 2])
				i += 2
				continue
			}
			out += md_escape('\\')
			i++
		} else if c == 96 {
			rel := s[i + 1..].index('`') or { -1 }
			if rel >= 0 {
				out += '<code>' + md_escape(s[i + 1..i + 1 + rel]) + '</code>'
				i += rel + 2
			} else {
				out += md_escape('`')
				i++
			}
		} else if c == `*` && i + 1 < s.len && s[i + 1] == `*` {
			rel := s[i + 2..].index('**') or { -1 }
			if rel >= 0 {
				out += '<strong>' + md_inline(s[i + 2..i + 2 + rel]) + '</strong>'
				i += rel + 4
			} else {
				out += md_escape('**')
				i += 2
			}
		} else if c == `*` || c == `_` {
			q := s[i..i + 1]
			rel := s[i + 1..].index(q) or { -1 }
			if rel >= 0 {
				out += '<em>' + md_inline(s[i + 1..i + 1 + rel]) + '</em>'
				i += rel + 2
			} else {
				out += md_escape(q)
				i++
			}
		} else if c == `!` && i + 1 < s.len && s[i + 1] == `[` {
			alt, src, next := md_link_target(s, i + 1)
			if next > 0 {
				out += '<img src="' + md_escape(src) + '" alt="' + md_escape(alt) + '" loading="lazy">'
				i = next
			} else {
				out += md_escape('!')
				i++
			}
		} else if c == `[` {
			text, href, next := md_link_target(s, i)
			if next > 0 {
				out += '<a href="' + md_escape(href) + '">' + md_inline(text) + '</a>'
				i = next
			} else {
				out += md_escape('[')
				i++
			}
		} else {
			out += md_escape(s[i..i + 1])
			i++
		}
	}
	return out
}

// md_link_target parses `[text](href)` starting at the `[` at pos. It
// returns the text, href and the index just past `)`, or next == -1 when
// the text at pos is not a link.
fn md_link_target(s string, pos int) (string, string, int) {
	end_rel := s[pos + 1..].index(']') or { return '', '', -1 }
	end := pos + 1 + end_rel
	if end + 1 >= s.len || s[end + 1] != `(` {
		return '', '', -1
	}
	close_rel := s[end + 2..].index(')') or { return '', '', -1 }
	close := end + 2 + close_rel
	href := s[end + 2..close].trim_space()
	return s[pos + 1..end], href, close + 1
}

fn md_is_list_marker(t string) (bool, bool) {
	// returns (is_item, is_ordered)
	if t.len >= 2 && (t[0] == `-` || t[0] == `*` || t[0] == `+`) && t[1] == ` ` {
		return true, false
	}
	mut i := 0
	for i < t.len && t[i] >= `0` && t[i] <= `9` {
		i++
	}
	if i > 0 && i + 1 < t.len && t[i] == `.` && t[i + 1] == ` ` {
		return true, true
	}
	return false, false
}

fn md_is_delim_row(t string) bool {
	inner := t.trim(' |')
	if inner == '' || !inner.contains('-') {
		return false
	}
	for ch in inner {
		if ch != `-` && ch != `:` && ch != ` ` && ch != `|` {
			return false
		}
	}
	return true
}

fn md_split_row(t string) []string {
	trimmed := t.trim_space().trim('|')
	raw := trimmed.split('|')
	mut cells := []string{}
	for rc in raw {
		cells << md_inline(rc.trim_space())
	}
	return cells
}

fn md_blocks(lines []string) []string {
	mut out := []string{}
	mut i := 0
	for i < lines.len {
		t := lines[i].trim_space()
		if t == '' {
			i++
			continue
		}
		if t.starts_with('```') {
			info := t[3..].trim_space()
			lang := info.split(' ')[0]
			mut code := []string{}
			i++
			for i < lines.len && !lines[i].trim_space().starts_with('```') {
				code << lines[i]
				i++
			}
			i++ // skip the closing fence
			cls := if lang != '' { ' class="language-${lang}"' } else { '' }
			out << '<pre><code${cls}>' + md_escape(code.join('\n')) + '</code></pre>'
			continue
		}
		if t[0] == `#` {
			mut lvl := 0
			for lvl < t.len && t[lvl] == `#` {
				lvl++
			}
			if lvl <= 6 && (lvl == t.len || t[lvl] == ` ` || t[lvl] == `\t`) {
				mut text := t[lvl..].trim_space()
				for text.ends_with('#') {
					text = text[..text.len - 1].trim_space()
				}
				out << '<h${lvl}>' + md_inline(text) + '</h${lvl}>'
				i++
				continue
			}
		}
		if t == '>' || t.starts_with('> ') || t.starts_with('>\t') {
			mut inner := []string{}
			for i < lines.len {
				lt := lines[i].trim_space()
				if lt == '' {
					inner << ''
					i++
				} else if lt == '>' {
					inner << ''
					i++
				} else if lt.starts_with('> ') || lt.starts_with('>\t') {
					inner << lines[i].trim_space()[2..]
					i++
				} else {
					break
				}
			}
			out << '<blockquote>\n' + md_blocks(inner).join('\n') + '\n</blockquote>'
			continue
		}
		if t.len >= 3 && (t == '---' || t == '***' || t == '___') {
			out << '<hr>'
			i++
			continue
		}
		if t.contains('|') && i + 1 < lines.len && md_is_delim_row(lines[i + 1].trim_space()) {
			head := md_split_row(t)
			mut rows := []string{}
			cols := head.len
			mut h := '<table>\n<thead>\n<tr>'
			for hc in head {
				h += '<th>' + hc + '</th>'
			}
			rows << h + '</tr>\n</thead>\n<tbody>'
			i += 2
			for i < lines.len {
				rt := lines[i].trim_space()
				if rt == '' || !rt.contains('|') {
					break
				}
				cells := md_split_row(rt)
				mut r := '<tr>'
				for n in 0 .. cols {
					cell := if n < cells.len { cells[n] } else { '' }
					r += '<td>' + cell + '</td>'
				}
				rows << r + '</tr>'
				i++
			}
			rows << '</tbody>\n</table>'
			out << rows.join('\n')
			continue
		}
		is_item, ordered := md_is_list_marker(t)
		if is_item {
			tag := if ordered { 'ol' } else { 'ul' }
			mut items := []string{}
			for i < lines.len {
				lt := lines[i].trim_space()
				mut item_ordered := false
				mut ok := false
				ok, item_ordered = md_is_list_marker(lt)
				if !ok || item_ordered != ordered {
					if lt == '' || (lines[i].len > 0
						&& (lines[i][0] == ` ` || lines[i][0] == `\t`) && lt != '') {
						if items.len > 0 && lt != '' {
							items[items.len - 1] += ' ' + lt
							i++
							continue
						}
					}
					break
				}
				text := if ordered { lt[lt.index(' ') or { 0 } + 1..] } else { lt[2..] }
				items << md_inline(text.trim_space())
				i++
			}
			mut l := '<${tag}>\n'
			for it in items {
				l += '<li>' + it + '</li>\n'
			}
			out << l + '</${tag}>'
			continue
		}
		mut para := []string{}
		for i < lines.len {
			pt := lines[i].trim_space()
			if pt == '' {
				break
			}
			peek_item, _ := md_is_list_marker(pt)
			if pt.starts_with('```') || pt[0] == `#` || pt == '>' || pt.starts_with('> ')
				|| pt.starts_with('>\t') || peek_item
				|| (pt.contains('|') && i + 1 < lines.len
					&& md_is_delim_row(lines[i + 1].trim_space())) {
				break
			}
			para << pt
			i++
		}
		out << '<p>' + md_inline(para.join(' ')) + '</p>'
	}
	return out
}

fn md_to_html(src string) string {
	return md_blocks(src.replace('\r\n', '\n').split_into_lines()).join('\n')
}
