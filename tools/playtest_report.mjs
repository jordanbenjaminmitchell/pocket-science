// Aggregates emulated playtest logs (docs/playtests/*.jsonl) into REPORT.md.
// Usage: node tools/playtest_report.mjs [dir]
import fs from "node:fs";
import path from "node:path";

const dir = process.argv[2] || "docs/playtests";
const order = ["novice", "casual", "builder", "saver", "gambler", "expert"];
const runs = [];
for (const f of fs.readdirSync(dir).filter((f) => f.endsWith(".jsonl"))) {
  for (const line of fs.readFileSync(path.join(dir, f), "utf8").split("\n")) {
    if (line.trim()) runs.push(JSON.parse(line));
  }
}
const catalog = fs.readFileSync("src/game/catalog.gd", "utf8");
const allFormulas = [...catalog.matchAll(/^\t"([a-z0-9]+)": \{"name": "([^"]+)", "r": (\d)/gm)].map((m) => ({ id: m[1], name: m[2], r: +m[3] }));
const formulaIds = new Set();
const names = {};
for (const f of allFormulas) { if (!formulaIds.has(f.id)) { formulaIds.add(f.id); names[f.id] = f.name; } }

const pct = (a, b) => (b ? ((100 * a) / b).toFixed(0) + "%" : "-");
const avg = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
const f1 = (x) => x.toFixed(1);
const median = (xs) => { const s = [...xs].sort((a, b) => a - b); return s.length ? s[Math.floor(s.length / 2)] : 0; };

let md = `# Emulated playtest report\n\n`;
md += `${runs.length} complete runs by ${new Set(runs.map((r) => r.persona)).size} simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated ${new Date().toISOString().slice(0, 10)}.\n\n`;
md += `Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).\n\n`;

// 1. Per persona
md += `## 1. How each kind of player does\n\n| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |\n|---|---|---|---|---|---|---|---|---|\n`;
for (const p of order) {
  const rs = runs.filter((r) => r.persona === p);
  if (!rs.length) continue;
  const wins = rs.filter((r) => r.won).length;
  const shots = rs.reduce((a, r) => a + r.shots, 0);
  const pots = rs.reduce((a, r) => a + r.pots, 0);
  const tables = rs.reduce((a, r) => a + r.tables.length, 0);
  md += `| ${p} | ${rs.length} | ${pct(wins, rs.length)} | ${f1(avg(rs.map((r) => r.cleared)))} | ${median(rs.map((r) => r.cleared))} | ${pct(pots, shots)} balls/shot | ${f1(shots / tables)} | ${Math.round(avg(rs.map((r) => r.best_shot)))} | ${f1(avg(rs.map((r) => r.bounties)))} |\n`;
}

// 2. Where runs end
md += `\n## 2. Where runs end (table reached)\n\n| Player | ` + [...Array(9).keys()].map((i) => `T${i + 1}`).join(" | ") + ` | Win |\n|---|` + "---|".repeat(10) + `\n`;
for (const p of order) {
  const rs = runs.filter((r) => r.persona === p);
  if (!rs.length) continue;
  const cells = [...Array(9).keys()].map((i) => rs.filter((r) => !r.won && r.died_at === i).length || "");
  md += `| ${p} | ${cells.join(" | ")} | ${rs.filter((r) => r.won).length} |\n`;
}

// 3. Table difficulty
md += `\n## 3. Table difficulty (all players)\n\n| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |\n|---|---|---|---|---|---|\n`;
for (let i = 0; i < 9; i++) {
  const ts = runs.flatMap((r) => r.tables.filter((t) => t.i === i));
  if (!ts.length) continue;
  const won = ts.filter((t) => t.won);
  const lost = ts.filter((t) => !t.won);
  md += `| ${i + 1} | ${ts[0].target} | ${ts.length} | ${pct(won.length, ts.length)} | ${f1(avg(won.map((t) => t.score / t.target)))}× | ${f1(avg(lost.map((t) => t.score / t.target)))}× |\n`;
}

// 4. Bosses
md += `\n## 4. Boss lethality\n\n| Boss | Attempts | Lost there | Death rate |\n|---|---|---|---|\n`;
const bossRows = {};
for (const r of runs) for (const t of r.tables) if (t.anomaly) {
  bossRows[t.anomaly] ??= { a: 0, d: 0 };
  bossRows[t.anomaly].a++;
  if (!t.won) bossRows[t.anomaly].d++;
}
for (const [b, v] of Object.entries(bossRows).sort((x, y) => y[1].d / y[1].a - x[1].d / x[1].a)) md += `| ${b} | ${v.a} | ${v.d} | ${pct(v.d, v.a)} |\n`;

// 5. Labs (non-boss)
md += `\n## 5. Lab difficulty (non-boss tables)\n\n| Lab | Attempts | Death rate |\n|---|---|---|\n`;
const labRows = {};
for (const r of runs) for (const t of r.tables) if (!t.anomaly) {
  labRows[t.lab] ??= { a: 0, d: 0 };
  labRows[t.lab].a++;
  if (!t.won) labRows[t.lab].d++;
}
for (const [l, v] of Object.entries(labRows)) md += `| ${l} | ${v.a} | ${pct(v.d, v.a)} |\n`;

// 6. Cues
md += `\n## 6. Starting cues\n\n| Cue | Runs | Win rate | Avg tables cleared |\n|---|---|---|---|\n`;
for (const c of [...new Set(runs.map((r) => r.cue))]) {
  const rs = runs.filter((r) => r.cue === c);
  md += `| ${c} | ${rs.length} | ${pct(rs.filter((r) => r.won).length, rs.length)} | ${f1(avg(rs.map((r) => r.cleared)))} |\n`;
}

// 7. Formulas
const overall = avg(runs.map((r) => r.cleared));
const fstats = {};
for (const id of formulaIds) fstats[id] = { bought: 0, owned: 0, clearedWhenOwned: [] };
for (const r of runs) {
  for (const p of r.purchases) if (p.type === "formula" && fstats[p.id]) fstats[p.id].bought++;
  // A formula "carried" a table if it was owned when that table was played (tables after its purchase).
  const owned = new Set();
  for (const t of r.tables) for (const id of t.formulas) owned.add(id);
  for (const id of owned) if (fstats[id]) { fstats[id].owned++; fstats[id].clearedWhenOwned.push(r.cleared); }
}
const rows = Object.entries(fstats).map(([id, s]) => ({ id, ...s, lift: s.clearedWhenOwned.length ? avg(s.clearedWhenOwned) - overall : null }));
md += `\n## 7. Formulas\n\nOverall average tables cleared: **${f1(overall)}**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.\n\n`;
md += `### Most bought\n\n| Formula | Bought | Runs owning | Lift |\n|---|---|---|---|\n`;
for (const r of [...rows].sort((a, b) => b.bought - a.bought).slice(0, 12)) md += `| ${names[r.id]} | ${r.bought} | ${r.owned} | ${r.lift === null ? "-" : (r.lift >= 0 ? "+" : "") + f1(r.lift)} |\n`;
md += `\n### Strongest by lift (owned by 6+ runs)\n\n| Formula | Runs owning | Lift |\n|---|---|---|\n`;
for (const r of rows.filter((r) => r.owned >= 6).sort((a, b) => b.lift - a.lift).slice(0, 10)) md += `| ${names[r.id]} | ${r.owned} | +${f1(r.lift)} |\n`;
md += `\n### Weakest by lift (owned by 6+ runs)\n\n| Formula | Runs owning | Lift |\n|---|---|---|\n`;
for (const r of rows.filter((r) => r.owned >= 6).sort((a, b) => a.lift - b.lift).slice(0, 10)) md += `| ${names[r.id]} | ${r.owned} | ${f1(r.lift)} |\n`;
const never = rows.filter((r) => r.bought === 0).map((r) => names[r.id]);
md += `\n**Never bought (${never.length}):** ${never.join(", ") || "none"}\n`;

// 8. Fouls and reagents
const fouls = {};
let totalShots = 0;
for (const r of runs) { totalShots += r.shots; for (const [k, v] of Object.entries(r.fouls)) fouls[k] = (fouls[k] || 0) + v; }
md += `\n## 8. Fouls and reagents\n\nOf ${totalShots} shots: ` + Object.entries(fouls).map(([k, v]) => `${k} ${pct(v, totalShots)}`).join(", ") + `.\n\n`;
const reag = {};
for (const r of runs) for (const [k, v] of Object.entries(r.reagents_used)) reag[k] = (reag[k] || 0) + v;
md += `Reagents used: ` + Object.entries(reag).map(([k, v]) => `${k} ×${v}`).join(", ") + `.\n`;

fs.writeFileSync(path.join(dir, "REPORT.md"), md);
console.log(md);
