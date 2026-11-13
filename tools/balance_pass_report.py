"""Summarize current headless JSONL playtests without touching earlier reports.

Usage: python tools/balance_pass_report.py docs/playtests/balance_pass2
"""

from collections import Counter, defaultdict
from pathlib import Path
import json
import statistics as stats
import sys


def avg(values):
    return sum(values) / len(values) if values else 0.0


def pct(part, whole):
    return f"{100 * part / whole:.0f}%" if whole else "—"


folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("docs/playtests/balance_pass2")
plans = {}
plan_path = folder / "plans.jsonl"
if plan_path.exists():
    for line in plan_path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            row = json.loads(line)
            plans[row["seed"]] = row["boards"]
runs = []
for path in sorted(folder.glob("*.jsonl")):
    if path.name == "plans.jsonl":
        continue
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            row = json.loads(line)
            row["source"] = path.stem
            runs.append(row)

out = ["# Balance pass 2: headless physics playtests", ""]
out += [
    f"{len(runs)} completed bot runs. These use real table physics, scorer and run state; "
    "the bot's aiming, shopping and Catalyst placement are heuristics. "
    "Its Catalyst lookahead can preview the full noisy shot, which gives it more information than a human would usually have. "
    "Small groups and late tables have wide uncertainty.",
    "",
    "These physics batches started before the latest uncommitted game edits. The current scoring probe was rerun separately; "
    "the physics results describe the earlier snapshot and are directional for the current working tree.",
    "",
    "## Runs by batch",
    "",
    "| Batch | Runs | Wins | Average tables cleared | Pots per shot | Catalyst uses per run |",
    "|---|---:|---:|---:|---:|---:|",
]
groups = defaultdict(list)
for run in runs:
    groups[run["source"]].append(run)
for name, rows in sorted(groups.items()):
    out.append(
        f"| {name} | {len(rows)} | {pct(sum(r['won'] for r in rows), len(rows))} | "
        f"{avg([r['cleared'] for r in rows]):.1f} | "
        f"{sum(r['pots'] for r in rows) / max(1, sum(r['shots'] for r in rows)):.2f} | "
        f"{sum(sum(r.get('catalysts_used', {}).values()) for r in rows) / len(rows):.1f} |"
    )

controls = {r["seed"]: r for r in groups.get("builder_control", [])}
grant_groups = {name: rows for name, rows in groups.items() if name.startswith("builder_") and name not in ("builder_control", "builder_on", "builder_off")}
if grant_groups:
    out += ["", "## Free starting Catalyst experiments", "", "Same-seed controls use the builder bot with ordinary shop access. These grants are free, so differences measure opportunity and run impact rather than purchase value. Small matched groups are noisy.", "", "| Grant | Matched runs | Mean table difference | Uses | Tested shots | Actionable shots |", "|---|---:|---:|---:|---:|---:|"]
    for name, rows in sorted(grant_groups.items()):
        matched = [(r, controls[r["seed"]]) for r in rows if r["seed"] in controls]
        tool = name.removeprefix("builder_")
        uses = sum(r.get("catalysts_used", {}).get(tool, 0) for r, _ in matched)
        tested_count = sum(r.get("catalyst_trials", {}).get(tool, {}).get("tested", 0) for r, _ in matched)
        actionable_count = sum(r.get("catalyst_trials", {}).get(tool, {}).get("actionable", 0) for r, _ in matched)
        delta = avg([r["cleared"] - c["cleared"] for r, c in matched])
        out.append(f"| {tool} | {len(matched)} | {delta:+.1f} | {uses} | {tested_count} | {actionable_count} |")

out += ["", "## Table scores", "", "The clear percentage is conditional on reaching that table. Lost score is the average share of target reached on failed attempts.", "", "| Table | Target | Attempts | Cleared | Median score / target | Lost score / target | Average shots | Average pots |", "|---|---:|---:|---:|---:|---:|---:|---:|"]
for i in range(9):
    rows = [t for r in runs if r["source"].endswith("_on") and not r.get("grant") for t in r["tables"] if t["i"] == i]
    if not rows:
        continue
    ratios = [t["score"] / t["target"] for t in rows]
    lost = [t["score"] / t["target"] for t in rows if not t["won"]]
    lost_cell = f"{avg(lost):.2f}×" if lost else "—"
    pots_cell = f"{avg([t['pots'] for t in rows]):.1f}" if all("pots" in t for t in rows) else "—"
    out.append(
        f"| {i + 1} | {rows[0]['target']} | {len(rows)} | {pct(sum(t['won'] for t in rows), len(rows))} | "
        f"{stats.median(ratios):.2f}× | {lost_cell} | {avg([t['shots'] for t in rows]):.1f} | "
        f"{pots_cell} |"
    )

out += ["", "## Clear rates by skill and table", "", "| Batch | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 |", "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
for name, rows in sorted(groups.items()):
    if not name.endswith("_on") or any(r.get("grant") for r in rows):
        continue
    cells = []
    for i in range(9):
        tables = [t for r in rows for t in r["tables"] if t["i"] == i]
        cells.append(pct(sum(t["won"] for t in tables), len(tables)))
    out.append(f"| {name} | " + " | ".join(cells) + " |")

board_rows = defaultdict(list)
for r in runs:
    if not r["source"].endswith("_on") or r.get("grant"):
        continue
    for t in r["tables"]:
        board_id = t.get("id") or (plans.get(r["seed"], [])[t["i"]] if len(plans.get(r["seed"], [])) > t["i"] else "")
        if board_id:
            board_rows[board_id].append(t)
if board_rows:
    out += ["", "## Boards with at least three attempts", "", f"{len(board_rows)} distinct board IDs were attempted in Catalyst-on baseline runs.", "", "| Board ID | Attempts | Cleared | Median score / target |", "|---|---:|---:|---:|"]
    for name, rows in sorted(board_rows.items(), key=lambda p: (avg([t["score"] / t["target"] for t in p[1]]), p[0])):
        if len(rows) < 3:
            continue
        out.append(f"| {name} | {len(rows)} | {pct(sum(t['won'] for t in rows), len(rows))} | {stats.median([t['score'] / t['target'] for t in rows]):.2f}× |")

buy = Counter()
use = Counter()
tested = Counter()
actionable = Counter()
for r in runs:
    if not r["source"].endswith("_on") or r.get("grant"):
        continue
    buy.update(p["id"] for p in r.get("purchases", []) if p["type"] == "item")
    use.update(r.get("catalysts_used", {}))
    for name, values in r.get("catalyst_trials", {}).items():
        tested[name] += values.get("tested", 0)
        actionable[name] += values.get("actionable", 0)
out += ["", "## Catalyst activity", "", "Includes cue kit uses. A zero use count does not show that a tool is weak unless the bot owned and considered it often.", "", "| Catalyst ID | Bought | Uses |", "|---|---:|---:|"]
for name in sorted(set(buy) | set(use), key=lambda n: (-use[n], n)):
    out.append(f"| {name} | {buy[name]} | {use[name]} |")
if tested:
    out += ["", "## Catalyst trial opportunities", "", "A trial is one shot where the bot owned the tool and had a valid placement; actionable means the best tested placement beat the no-tool shot by the spending threshold.", "", "| Catalyst ID | Tested shots | Actionable |", "|---|---:|---:|"]
    for name in sorted(tested, key=lambda n: (-actionable[n], n)):
        out.append(f"| {name} | {tested[name]} | {actionable[name]} |")

result = "\n".join(out) + "\n"
target = folder / "REPORT.md"
target.write_text(result, encoding="utf-8")
print(target)
