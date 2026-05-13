"""
FM4M-only fill: loads benchmark_cache.json (DC scores present),
calls FM4M API for datasets where fm4m == "N/A", updates cache,
then regenerates both HTMLs.
"""
import json, random, requests
import numpy as np
import pandas as pd
from pathlib import Path

FM4M_API  = "http://localhost:8090"
_BASE      = Path(__file__).parent
DATA_BASE  = _BASE / "MS_prediction dataset"
CACHE_FILE = _BASE / "benchmark_cache.json"
SAMPLE_N  = 100

DATASETS = {
    "bbbp":     {"input": DATA_BASE/"BBBP/BBBP_input.csv",             "output": DATA_BASE/"BBBP/BBBP_output.csv",             "smiles_col":"smiles", "task_type":"classification", "label":"BBBP"},
    "lipo":     {"input": DATA_BASE/"Lipophilicity/Lipophilicity_input.csv", "output": DATA_BASE/"Lipophilicity/Lipophilicity_output.csv", "smiles_col":"smiles", "task_type":"regression",     "label":"Lipophilicity (LogD)"},
    "esol":     {"input": DATA_BASE/"ESOL/ESOL_input.csv",              "output": DATA_BASE/"ESOL/ESOL_output.csv",              "smiles_col":"smiles", "task_type":"regression",     "label":"ESOL (LogS)"},
    "freesolv": {"input": DATA_BASE/"FreeSolv/FreeSolv_input.csv",      "output": DATA_BASE/"FreeSolv/FreeSolv_output.csv",      "smiles_col":"smiles", "task_type":"regression",     "label":"FreeSolv (ΔG)"},
    "bace":     {"input": DATA_BASE/"bace/bace_input.csv",              "output": DATA_BASE/"bace/bace_output_class.csv",        "smiles_col":"mol",    "task_type":"classification", "label":"BACE"},
    "tox21":    {"input": DATA_BASE/"TOX21/tox21_input.csv",            "output": DATA_BASE/"TOX21/tox21_output.csv",            "smiles_col":"smiles", "task_type":"classification", "label":"Tox21"},
    "clintox":  {"input": DATA_BASE/"clintox/clintox_input.csv",        "output": DATA_BASE/"clintox/clintox_output.csv",        "smiles_col":"smiles", "task_type":"classification", "label":"ClinTox"},
    "sider":    {"input": DATA_BASE/"sider/sider_input.csv",            "output": DATA_BASE/"sider/sider_output.csv",            "smiles_col":"smiles", "task_type":"classification", "label":"SIDER"},
    "hiv":      {"input": DATA_BASE/"HIV/HIV_input.csv",                "output": DATA_BASE/"HIV/HIV_output.csv",                "smiles_col":"smiles", "task_type":"classification", "label":"HIV"},
}


def _batch_fm4m(smiles_list):
    try:
        r = requests.post(f"{FM4M_API}/predict/batch/ml",
                          json={"smiles_list": smiles_list}, timeout=300)
        if r.status_code == 200:
            data = r.json()
            return data.get("results", data) if isinstance(data, dict) else data
    except Exception as e:
        print(f"    FM4M batch error: {e}")
    return [{} for _ in smiles_list]


def _get_fm4m_pred(result: dict, dataset: str, task_col: str):
    fm4m = result.get("fm4m_predictions", {})
    if not fm4m or dataset not in fm4m:
        return None
    entry = fm4m[dataset]
    if isinstance(entry, dict):
        if task_col in entry:
            v = entry[task_col]
            return float(v) if isinstance(v, (int, float)) else None
        for v in entry.values():
            if isinstance(v, (int, float)):
                return float(v)
    if isinstance(entry, (int, float)):
        return float(entry)
    return None


def needs_fm4m(dataset_cache: dict) -> bool:
    for scores in dataset_cache.get("tasks", {}).values():
        if scores.get("fm4m") == "N/A":
            return True
    return False


def fill_fm4m_for(name: str, cfg: dict, dataset_cache: dict) -> dict:
    print(f"\n[{name.upper()}] Running FM4M only …")
    df_in  = pd.read_csv(cfg["input"])
    df_out = pd.read_csv(cfg["output"])
    smiles_col = cfg["smiles_col"]
    tasks = list(df_out.columns)

    n = min(SAMPLE_N, len(df_in))
    idx = random.Random(42).sample(range(len(df_in)), n)
    smiles_list = [df_in[smiles_col].iloc[i] for i in idx]
    labels_mat  = df_out.values[idx]

    BATCH = 50
    fm_results = []
    for start in range(0, n, BATCH):
        batch = smiles_list[start:start+BATCH]
        print(f"    batch {start+len(batch)}/{n} …")
        fm_results.extend(_batch_fm4m(batch))

    fm_preds_per_task = {t: [] for t in tasks}
    true_per_task     = {t: [] for t in tasks}
    for j, (fm_result, label_row) in enumerate(zip(fm_results, labels_mat)):
        for t_idx, task in enumerate(tasks):
            true_val = label_row[t_idx]
            try:
                tv = float(true_val)
            except (TypeError, ValueError):
                continue
            if np.isnan(tv):
                continue
            fm_pred = _get_fm4m_pred(fm_result, name, task)
            true_per_task[task].append(tv)
            fm_preds_per_task[task].append(fm_pred)

    # Merge into existing task scores
    updated = dict(dataset_cache)
    for task in tasks:
        true_arr = np.array(true_per_task[task])
        if len(true_arr) < 10:
            continue
        fm_arr = np.array([p if p is not None else np.nan for p in fm_preds_per_task[task]])
        score_fm = None
        if cfg["task_type"] == "classification":
            from sklearn.metrics import roc_auc_score
            mask = ~np.isnan(fm_arr)
            try:
                if mask.sum() >= 10 and len(np.unique(true_arr[mask])) == 2:
                    score_fm = roc_auc_score(true_arr[mask], fm_arr[mask])
            except Exception:
                pass
        else:
            from sklearn.metrics import r2_score
            mask = ~np.isnan(fm_arr)
            try:
                if mask.sum() >= 10:
                    score_fm = r2_score(true_arr[mask], fm_arr[mask])
            except Exception:
                pass

        fm4m_val = round(float(score_fm), 4) if score_fm is not None else "N/A"
        if task in updated["tasks"]:
            updated["tasks"][task]["fm4m"] = fm4m_val
        else:
            dc_val = dataset_cache["tasks"].get(task, {}).get("dc", "N/A")
            updated["tasks"][task] = {"dc": dc_val, "fm4m": fm4m_val, "n": len(true_arr)}

    print(f"  Done. FM4M scores: { {t: updated['tasks'][t]['fm4m'] for t in list(updated['tasks'].keys())[:3]} } …")
    return updated


# ── HTML generation (same as benchmark_both_apps.py) ─────────────────────────

def _score_cell(v):
    if v == "N/A" or v is None:
        return '<td style="color:#666">N/A</td>'
    color = "#4ade80" if float(v) >= 0.75 else ("#fbbf24" if float(v) >= 0.5 else "#f87171")
    return f'<td style="color:{color};font-weight:600">{v:.4f}</td>'


def generate_html(results: list, title: str, filename: str):
    rows = []
    for r in results:
        if not r["tasks"]:
            continue
        dc_vals  = [v["dc"]   for v in r["tasks"].values() if isinstance(v.get("dc"),   float)]
        fm_vals  = [v["fm4m"] for v in r["tasks"].values() if isinstance(v.get("fm4m"), float)]
        mean_dc  = round(np.mean(dc_vals),  4) if dc_vals  else "N/A"
        mean_fm  = round(np.mean(fm_vals),  4) if fm_vals  else "N/A"

        task_rows = ""
        for task, scores in r["tasks"].items():
            task_rows += f"""
            <tr>
              <td style="padding-left:24px;color:#a0a0a0">{task}</td>
              <td>{scores['n']}</td>
              {_score_cell(scores['dc'])}
              {_score_cell(scores['fm4m'])}
            </tr>"""

        rows.append(f"""
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
  .legend span{{margin-right:16px}}
</style>
</head>
<body>
<h1>🧪 {title}</h1>
<p class="subtitle">MoleculeNet Benchmark — DeepChemUI vs FM4MUI | n=100 molecules/dataset</p>
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
{''.join(rows)}
</tbody>
</table>
<div class="legend">
  Metric: AUC-ROC (classification) or R² (regression)<br>
  <span style="color:#4ade80">■ ≥0.75 Good</span>
  <span style="color:#fbbf24">■ ≥0.50 Fair</span>
  <span style="color:#f87171">■ &lt;0.50 Poor</span>
</div>
</body></html>"""

    out = Path(r"C:\Users\takay\python379\DeepChem") / filename
    out.write_text(html, encoding="utf-8")
    print(f"  → Saved {out}")


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    if not CACHE_FILE.exists():
        print("ERROR: benchmark_cache.json not found. Run benchmark_both_apps.py first.")
        return

    cache = json.loads(CACHE_FILE.read_text(encoding="utf-8"))

    # Check FM4M API
    try:
        r = requests.get(f"{FM4M_API}/health", timeout=5)
        assert r.status_code == 200
        print("FM4M API: UP")
    except Exception:
        print("ERROR: FM4M API is DOWN at", FM4M_API)
        return

    # Fill missing FM4M results
    for name, cfg in DATASETS.items():
        if name not in cache:
            print(f"[{name}] not in cache, skipping")
            continue
        if needs_fm4m(cache[name]):
            cache[name] = fill_fm4m_for(name, cfg, cache[name])
            CACHE_FILE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"  Cache updated for {name}")
        else:
            print(f"[{name.upper()}] FM4M already complete, skipping")

    # Build results list in DATASETS order
    results = [cache[name] for name in DATASETS if name in cache]

    # Generate full HTML
    generate_html(results, "Molecular Property Prediction Benchmark — All Datasets", "benchmark_full.html")

    # Generate LIPO + BBBP HTML
    lb = [r for r in results if r["name"] in ("lipo", "bbbp")]
    generate_html(lb, "Benchmark — Lipophilicity &amp; BBBP", "benchmark_lipo_bbbp.html")

    print("\nDone! Opening both HTMLs …")
    import subprocess
    subprocess.Popen(["cmd", "/c", "start", "", r"C:\Users\takay\python379\DeepChem\benchmark_full.html"])
    subprocess.Popen(["cmd", "/c", "start", "", r"C:\Users\takay\python379\DeepChem\benchmark_lipo_bbbp.html"])


if __name__ == "__main__":
    main()
