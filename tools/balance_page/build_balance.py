"""Builds the balance page: marks rows that are new or changed since the last
pass (balance_prev.json), and adds the filter controls to the template."""
import json
import os
here = os.path.dirname(os.path.abspath(__file__))
proj = r'C:\Users\JordanMitchell\Documents\Codex\Pocket-Science-Revamp'
cur = json.load(open(os.path.join(proj, 'docs', 'balance_data.json'), encoding='utf-8'))
prev = json.load(open(os.path.join(here, 'balance_prev.json'), encoding='utf-8'))
old = {}
for s in prev['sections']:
    title = 'Exotic balls' if s['title'] == 'Special balls' else s['title']
    for r in s['rows']:
        key = r['key'].replace('special-balls-', 'exotic-balls-')
        old[(title, key)] = [c.replace('Special ball', 'Exotic ball').replace('special ball', 'Exotic ball') for c in r['cells']]
n_new = n_chg = 0
for s in cur['sections']:
    for r in s['rows']:
        o = old.get((s['title'], r['key']))
        if o is None:
            r['flag'] = 'new'
            n_new += 1
        elif o != r['cells']:
            r['flag'] = 'changed'
            r['was'] = [o[i] if i < len(o) and o[i] != c else '' for i, c in enumerate(r['cells'])]
            n_chg += 1
print('new', n_new, 'changed', n_chg)
data = json.dumps(cur, ensure_ascii=False).replace('</', '<\\/')

t = open(os.path.join(here, 'balance_template.html'), encoding='utf-8').read()


def sub(a, b):
    global t
    assert t.count(a) == 1, a[:70]
    t = t.replace(a, b)


sub('.empty { color: var(--muted); padding: 24px 0 }',
    '''.pill.new { background: var(--chalk-soft); color: var(--chalk) }
.pill.changed { background: var(--amber-soft); color: var(--amber) }
tr.flag-new td:not(.note), tr.flag-changed td:not(.note) { font-weight: 600 }
tr.flag-new td:first-child { box-shadow: inset 3px 0 0 var(--chalk) }
tr.flag-changed td:first-child { box-shadow: inset 3px 0 0 var(--amber) }
.was { display: block; font-weight: 400; font-size: 12px; color: var(--muted); text-decoration: line-through; margin-top: 2px }
select { font: 14px var(--body); padding: 6px 8px; border: 1px solid var(--line); border-radius: 8px; background: var(--panel); color: var(--fg) }
select:focus-visible { outline: 2px solid var(--chalk); outline-offset: 1px }
.empty { color: var(--muted); padding: 24px 0 }''')
sub('''    <label class="tog"><input type="checkbox" id="onlyNotes"> Only rows with notes</label>''',
    '''    <select id="show" aria-label="Which rows to show">
      <option value="all">All rows</option>
      <option value="touched">New or changed this pass</option>
      <option value="new">New only</option>
      <option value="changed">Changed only</option>
      <option value="notes">With a note</option>
      <option value="open">Notes not done yet</option>
      <option value="done">Notes done</option>
    </select>''')
sub('''<p class="sub">Every tunable number in the game. Type a note on any row: it saves as you go, and Claude reads your notes, makes the changes and replies under each one.</p>''',
    '''<p class="sub">Every tunable number in the game. Type a note on any row: it saves as you go, and Claude reads your notes, makes the changes and replies under each one. Rows in bold are new or changed in the latest pass; a changed cell shows its old value struck through.</p>''')
sub('''  const only = $("#onlyNotes").checked;''', '''  const show = $("#show").value;
  const keep = (r) => {
    const n = notes[r.key] || {};
    switch (show) {
      case "touched": return !!r.flag;
      case "new": return r.flag === "new";
      case "changed": return r.flag === "changed";
      case "notes": return !!(n.note || n.reply);
      case "open": return !!n.note && n.status !== "done";
      case "done": return n.status === "done";
    }
    return true;
  };''')
sub('''&& (!only || notes[r.key]?.note || notes[r.key]?.reply));''', '''&& keep(r));''')
sub('''<tr data-key="${r.key}" class="${n.note ? "has-note" : ""}">${r.cells.map((c, i) => `<td data-h="${esc(s.cols[i])}" class="${s.cols[i] === "Id" ? "id" : /^[$\\d+−×%-]/.test(c) && c.length < 14 ? "num" : ""}">${esc(c)}</td>`).join("")}''',
    '''<tr data-key="${r.key}" class="${n.note ? "has-note" : ""} ${r.flag ? "flag-" + r.flag : ""}">${r.cells.map((c, i) => `<td data-h="${esc(s.cols[i])}" class="${s.cols[i] === "Id" ? "id" : /^[$\\d+−×%-]/.test(c) && c.length < 14 ? "num" : ""}">${i === 0 && r.flag ? `<span class="pill ${r.flag}">${r.flag}</span>` : ""}${esc(c)}${r.was && r.was[i] ? `<span class="was">${esc(r.was[i])}</span>` : ""}</td>`).join("")}''')
sub('''$("#onlyNotes").onchange = render;''', '''$("#show").onchange = render;''')
sub('''el.innerHTML = all.map((c) =>''', '''el.innerHTML = all.map((c) =>''')
sub('''<p class="empty">No rows match. Clear the search or the notes filter.</p>''', '''<p class="empty">No rows match. Clear the search or set the filter back to All rows.</p>''')
assert 'onlyNotes' not in t
open(os.path.join(os.environ.get('BALANCE_OUT', here), 'pocket-science-balance.html'), 'w', encoding='utf-8').write(t.replace('__DATA__', data))
print([(s['title'], len(s['rows'])) for s in cur['sections']])
