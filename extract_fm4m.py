"""
Extract FM4M scores from old benchmark HTML and update benchmark_cache.json,
then regenerate both HTMLs.
"""
import re, json
import numpy as np
from pathlib import Path

OLD_HTML   = Path(r"C:\Users\takay\python379\DeepChem\Benchmark_ DeepChemUI vs FM4MUI — All Datasets_20260513_0115.html")
CACHE_FILE = Path(r"C:\Users\takay\python379\DeepChem\benchmark_cache.json")

# Dataset label → cache key
LABEL_TO_KEY = {
    "BBBP":                  "bbbp",
    "Lipophilicity (LogD)":  "lipo",
    "ESOL (LogS)":           "esol",
    "FreeSolv (ΔG)":    "freesolv",
    "BACE":                  "bace",
    "Tox21":                 "tox21",
    "ClinTox":               "clintox",
    "SIDER":                 "sider",
    "HIV":                   "hiv",
}

def parse_html_scores(html_path):
    html = html_path.read_text(encoding="utf-8")
    rows = re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.DOTALL)
    parsed = []
    for row in rows:
        cells = re.findall(r"<td[^>]*>(.*?)</td>", row, re.DOTALL)
        vals = [re.sub(r"<[^>]+>", "", c).strip() for c in cells]
        if len(vals) >= 4:
            parsed.append(vals)
    return parsed


def main():
    rows = parse_html_scores(OLD_HTML)
    cache = json.loads(CACHE_FILE.read_text(encoding="utf-8"))

    # Build a map: dataset_key -> {task_label -> fm4m_score}
    # Rows alternate: dataset-summary rows and task sub-rows
    # We detect dataset by matching its label; task rows have indented-looking labels
    current_ds_key = None
    fm4m_by_ds = {}

    for vals in rows:
        label, n_str, dc_str, fm_str = vals[0], vals[1], vals[2], vals[3]
        # Check if this is a dataset header row
        for lbl, key in LABEL_TO_KEY.items():
            if label.strip() == lbl:
                current_ds_key = key
                fm4m_by_ds.setdefault(key, {})
                break
        else:
            # It's a task row — associate with current dataset
            if current_ds_key and fm_str not in ("N/A", ""):
                try:
                    fm4m_by_ds[current_ds_key][label.strip()] = float(fm_str)
                except ValueError:
                    pass

    print("FM4M scores extracted:")
    for ds, tasks in fm4m_by_ds.items():
        print(f"  {ds}: {len(tasks)} tasks - {dict(list(tasks.items())[:3])}")

    # Merge into cache
    for ds_key, task_fm in fm4m_by_ds.items():
        if ds_key not in cache:
            continue
        for task, fm_score in task_fm.items():
            if task in cache[ds_key]["tasks"]:
                cache[ds_key]["tasks"][task]["fm4m"] = fm_score
            else:
                cache[ds_key]["tasks"][task] = {"dc": "N/A", "fm4m": fm_score, "n": cache[ds_key]["n_molecules"]}

    CACHE_FILE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
    print("\nCache updated with FM4M scores.")

    # Regenerate HTMLs
    generate_htmls(cache)


def _score_cell(v):
    if v == "N/A" or v is None:
        return '<td style="color:#666">N/A</td>'
    color = "#4ade80" if float(v) >= 0.75 else ("#fbbf24" if float(v) >= 0.5 else "#f87171")
    return f'<td style="color:{color};font-weight:600">{float(v):.4f}</td>'


def generate_html(results, title, filename):
    rows_html = []
    for r in results:
        if not r["tasks"]:
            continue
        dc_vals = [v["dc"]   for v in r["tasks"].values() if isinstance(v.get("dc"),   float)]
        fm_vals = [v["fm4m"] for v in r["tasks"].values() if isinstance(v.get("fm4m"), float)]
        mean_dc = round(float(np.mean(dc_vals)), 4) if dc_vals else "N/A"
        mean_fm = round(float(np.mean(fm_vals)), 4) if fm_vals else "N/A"

        task_rows = ""
        for task, scores in r["tasks"].items():
            task_rows += f"""
            <tr>
              <td style="padding-left:24px;color:#a0a0a0">{task}</td>
              <td>{scores['n']}</td>
              {_score_cell(scores['dc'])}
              {_score_cell(scores['fm4m'])}
            </tr>"""

        rows_html.append(f"""
        <tr style="background:#1e2130">
          <td style="font-weight:700;color:#93c5fd">{r['label']}</td>
          <td>{r['n_molecules']}</td>
          {_score_cell(mean_dc)}
          {_score_cell(mean_fm)}
        </tr>
        {task_rows}""")

    html = f"""<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
  body{{background:#0f1117;color:#e0e0e0;font-family:'Segoe UI',sans-serif;margin:0;padding:24px}}
  h1{{color:#93c5fd;margin-bottom:4px}}
  .subtitle{{color:#6b7280;margin-bottom:24px;font-size:14px}}
  table{{border-collapse:collapse;width:100%;max-width:900px}}
  th{{background:#1e2130;color:#93c5fd;padding:10px 14px;text-align:left;border-bottom:2px solid #374151}}
  td{{padding:8px 14px;border-bottom:1px solid #1e2130}}
  tr:hover td{{background:#1a1f2e}}
  .legend{{margin-top:20px;font-size:12px;color:#6b7280}}
</style>
</head>
<body>
<h1>🧪 {title}</h1>
<p class="subtitle">MoleculeNet Benchmark — DeepChemUI vs FM4MUI</p>
<table>
<thead>
  <tr>
    <th>Dataset / Task</th>
    <th>N</th>
    <th>DeepChemUI</th>
    <th>FM4MUI</th>
  </tr>
</thead>
<tbody>
{''.join(rows_html)}
</tbody>
</table>
<div class="legend">
  Metric: AUC-ROC (classification) or R&sup2; (regression) &nbsp;|&nbsp;
  <span style="color:#4ade80">&#9632; &ge;0.75 Good</span> &nbsp;
  <span style="color:#fbbf24">&#9632; &ge;0.50 Fair</span> &nbsp;
  <span style="color:#f87171">&#9632; &lt;0.50 Poor</span>
</div>
</body></html>"""

    out = Path(r"C:\Users\takay\python379\DeepChem") / filename
    out.write_text(html, encoding="utf-8")
    print(f"  → {out}")


DATASET_ORDER = ["bbbp", "lipo", "esol", "freesolv", "bace", "tox21", "clintox", "sider", "hiv"]


def generate_htmls(cache):
    results = [cache[k] for k in DATASET_ORDER if k in cache]
    generate_html(results, "Molecular Property Prediction Benchmark — All Datasets", "benchmark_full.html")

    lb = [cache[k] for k in ("lipo", "bbbp") if k in cache]
    generate_html(lb, "Benchmark — Lipophilicity &amp; BBBP", "benchmark_lipo_bbbp.html")

    import subprocess
    subprocess.Popen(["cmd", "/c", "start", "", r"C:\Users\takay\python379\DeepChem\benchmark_full.html"])
    subprocess.Popen(["cmd", "/c", "start", "", r"C:\Users\takay\python379\DeepChem\benchmark_lipo_bbbp.html"])
    print("Opened both HTMLs.")


if __name__ == "__main__":
    main()
