module main

fn test_md_heading_and_paragraph() {
	assert md_to_html('# Hi there') == '<h1>Hi there</h1>'
	assert md_to_html('Just a line.') == '<p>Just a line.</p>'
}

fn test_md_inline() {
	assert md_inline('**bold** and *em* and `code`') == '<strong>bold</strong> and <em>em</em> and <code>code</code>'
	assert md_inline('**bold with `code` inside**') == '<strong>bold with <code>code</code> inside</strong>'
	assert md_inline('[V](https://vlang.io)') == '<a href="https://vlang.io">V</a>'
	assert md_inline('![alt](/me-256.webp)') == '<img src="/me-256.webp" alt="alt" loading="lazy">'
	assert md_inline('a < b & c') == 'a &lt; b &amp; c'
	assert md_inline('`a < b`') == '<code>a &lt; b</code>'
}

fn test_md_fence() {
	got := md_to_html('```v\nprintln(1)\n```')
	assert got == '<pre><code class="language-v">println(1)</code></pre>'
}

fn test_md_lists() {
	ul := md_to_html('- a\n- b')
	assert ul.contains('<ul>') && ul.contains('<li>a</li>') && ul.contains('<li>b</li>')
	ol := md_to_html('1. first\n2. second')
	assert ol.contains('<ol>') && ol.contains('<li>first</li>')
}

fn test_md_blockquote_table_hr() {
	q := md_to_html('> quoted **text**')
	assert q.contains('<blockquote>') && q.contains('<strong>text</strong>')
	t := md_to_html('| a | b |\n|---|---|\n| 1 | 2 |')
	assert t.contains('<table>') && t.contains('<th>a</th>') && t.contains('<td>2</td>')
	assert md_to_html('---') == '<hr>'
}

fn test_md_no_fold_leak() {
	m := parse_fm('problem: >-\n  line one\n  line two\ntitle: T')
	assert m['problem'] == ['line one line two']
	assert m['title'] == ['T']
}
