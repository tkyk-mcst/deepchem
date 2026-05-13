"""
Benchmark: DeepChemUI vs FM4MUI on Navin MoleculeNet datasets.
Calls both running APIs and compares predictions vs ground truth.

Usage:
  python benchmark_both_apps.py            # all available datasets
  python benchmark_both_apps.py bbbp lipo  # specific datasets

Outputs:
  benchmark_full.html      — all datasets
  benchmark_lipo_bbbp.html — LIPO + BBBP only
"""
import sys
import os
import json
import time
import random
import requests
import numpy as np
import pandas as pd
from pathlib import Path

DEEPCHEM_API = "http://localhost:8282"
FM4M_API     = "http://localhost:8090"
DATA_BASE    = Path(r"C:\Users\takay\python379\DeepChem\MS_prediction dataset")
SAMPLE_N     = 100   # molecules per dataset for benchmark (speed)

DATASETS = {
    "bbbp": {
        "input":  DATA_BASE / "BBBP/BBBP_input.csv",
        "output": DATA_BASE / "BBBP/BBBP_output.csv",
        "smiles_col": "smiles",
        "task_type": "classification",
        "label": "BBBP",
    },
    "lipo": {
        "input":  DATA_BASE / "Lipophilicity/Lipophilicity_input.csv",
        "output": DATA_BASE / "Lipophilicity/Lipophilicity_output.csv",
        "smiles_col": "smiles",
        "task_type": "regression",
        "label": "Lipophilicity (LogD)",
    },
    "esol": {
        "input":  DATA_BASE / "ESOL/ESOL_input.csv",
        "output": DATA_BASE / "ESOL/ESOL_output.csv",
        "smiles_col": "smiles",
        "task_type": "regression",
        "label": "ESOL (LogS)",
    },
    "freesolv": {
        "input":  DATA_BASE / "FreeSolv/FreeSolv_input.csv",
        "output": DATA_BASE / "FreeSolv/FreeSolv_output.csv",
        "smiles_col": "smiles",
        "task_type": "regression",
        "label": "FreeSolv (ΔG)",
    },
    "bace": {
        "input":  DATA_BASE / "bace/bace_input.csv",
        "output": DATA_BASE / "bace/bace_output_class.csv",
        "smiles_col": "mol",
        "task_type": "classification",
        "label": "BACE",
    },
    "tox21": {
        "input":  DATA_BASE / "TOX21/tox21_input.csv",
        "output": DATA_BASE / "TOX21/tox21_output.csv",
        "smiles_col": "smiles",
        "task_type": "classification",
        "label": "Tox21",
    },
    "clintox": {
        "input":  DATA_BASE / "clintox/clintox_input.csv",
        "output": DATA_BASE / "clintox/clintox_output.csv",
        "smiles_col": "smiles",
        "task_type": "classification",
        "label": "ClinTox",
    },
    "sider": {
        "input":  DATA_BASE / "sider/sider_input.csv",
        "output": DATA_BASE / "sider/sider_output.csv",
        "smiles_col": "smiles",
        "task_type": "classification",
        "label": "SIDER",
    },
    "hiv": {
        "input":  DATA_BASE / "HIV/HIV_input.csv",
        "output": DATA_BASE / "HIV/HIV_output.csv",
        "smiles_col": "smiles",
        "task_type": "classification",
        "label": "HIV",
    },
    # toxcast (617 tasks) and qm8 excluded — no trained models in either app
}


def _api_predict_batch(api_base: str, smiles_list: list, fm4m: bool = False) -> list:
    """Call batch predict endpoint and return list of result dicts."""
    try:
        if fm4m:
            path = f"{api_base}/predict/batch/ml"
            payload = {"smiles_list": smiles_list}
        else:
            path = f"{api_base}/predict/batch"
            payload = {"smiles_list": smiles_list}
        r = requests.post(path, json=payload, timeout=300)
        if r.status_code == 200:
            data = r.json()
            return data.get("results", data) if isinstance(data, dict) else data
    except Exception:
        pass
    return [{} for _ in smiles_list]


def _check_api(api_base: str) -> bool:
    try:
        r = requests.get(f"{api_base}/health", timeout=5)
        return r.status_code == 200
    except Exception:
        return False


def _get_dc_pred(result: dict, dataset: str, task_col: str):
    """Extract DeepChemUI prediction for a task."""
    preds = result.get("predictions", {})
    if not preds:
        return None
    key_map = {
        "bbbp": "bbbp", "lipo": "lipo", "esol": "solubility",
        "freesolv": "freesolv", "bace": "bace",
        "tox21": "tox21", "clintox": "clintox",
        "sider": "sider", "hiv": "hiv",
        "toxcast": None, "qm8": None,
    }
    pred_key = key_map.get(dataset)
    if pred_key is None or pred_key not in preds:
        return None
    entry = preds[pred_key]
    if not isinstance(entry, dict):
        return float(entry) if entry is not None else None
    # Multi-task: task_col is a sub-key (tox21, clintox, sider)
    if task_col in entry:
        sub = entry[task_col]
        if isinstance(sub, dict):
            for k in ("probability", "logD", "logS", "dG", "value"):
                if k in sub and isinstance(sub[k], (int, float)):
                    return float(sub[k])
            for v in sub.values():
                if isinstance(v, (int, float)):
                    return float(v)
        return float(sub) if isinstance(sub, (int, float)) else None
    # Single-task: pick first numeric field
    for k in ("probability", "logD", "logS", "dG", "value"):
        if k in entry and isinstance(entry[k], (int, float)):
            return float(entry[k])
    for v in entry.values():
        if isinstance(v, (int, float)):
            return float(v)
    return None


def _get_fm4m_pred(result: dict, dataset: str, task_col: str):
    """Extract FM4MUI prediction for a task."""
    fm4m = result.get("fm4m_predictions", {})
    if not fm4m or dataset not in fm4m:
        return None
    entry = fm4m[dataset]
    if isinstance(entry, dict):
        if task_col in entry:
            return entry[task_col]
        # Use first available task prediction
        for v in entry.values():
            if isinstance(v, (int, float)):
                return v
    return None


def benchmark_dataset(name: str, cfg: dict):
    """Run benchmark on one dataset. Returns results dict."""
    print(f"\n[{name.upper()}] Loading data …")
    df_in  = pd.read_csv(cfg["input"])
    df_out = pd.read_csv(cfg["output"])
    smiles_col = cfg["smiles_col"]
    tasks = list(df_out.columns)

    # Sample
    n = min(SAMPLE_N, len(df_in))
    idx = random.Random(42).sample(range(len(df_in)), n)
    smiles_list = [df_in[smiles_col].iloc[i] for i in idx]
    labels_mat  = df_out.values[idx]  # (n, T)

    print(f"  {n} molecules, {len(tasks)} tasks …")

    dc_preds_per_task  = {t: [] for t in tasks}
    fm_preds_per_task  = {t: [] for t in tasks}
    true_per_task      = {t: [] for t in tasks}

    dc_ok = _check_api(DEEPCHEM_API)
    fm_ok = _check_api(FM4M_API)
    print(f"  DC reachable: {dc_ok}, FM reachable: {fm_ok}")

    # Batch API calls — one request per dataset instead of N requests
    BATCH = 50
    dc_results, fm_results = [], []
    for start in range(0, n, BATCH):
        batch = smiles_list[start:start+BATCH]
        print(f"    batch {start+len(batch)}/{n} …")
        if dc_ok:
            dc_results.extend(_api_predict_batch(DEEPCHEM_API, batch, fm4m=False))
        else:
            dc_results.extend([{} for _ in batch])
        if fm_ok:
            fm_results.extend(_api_predict_batch(FM4M_API, batch, fm4m=True))
        else:
            fm_results.extend([{} for _ in batch])

    for j, (dc_result, fm_result, label_row) in enumerate(zip(dc_results, fm_results, labels_mat)):
        for t_idx, task in enumerate(tasks):
            true_val = label_row[t_idx]
            if np.isnan(float(true_val) if true_val is not None else float('nan')):
                continue

            dc_pred = _get_dc_pred(dc_result, name, task)
            fm_pred = _get_fm4m_pred(fm_result, name, task)

            true_per_task[task].append(float(true_val))
            dc_preds_per_task[task].append(dc_pred)
            fm_preds_per_task[task].append(fm_pred)

    # Score per task
    task_scores = {}
    for task in tasks:
        true_arr = np.array(true_per_task[task])
        if len(true_arr) < 10:
            continue
        dc_arr = np.array([p if p is not None else np.nan for p in dc_preds_per_task[task]])
        fm_arr = np.array([p if p is not None else np.nan for p in fm_preds_per_task[task]])

        score_dc, score_fm = None, None
        if cfg["task_type"] == "classification":
            from sklearn.metrics import roc_auc_score
            mask_dc = ~np.isnan(dc_arr)
            mask_fm = ~np.isnan(fm_arr)
            try:
                if mask_dc.sum() >= 10 and len(np.unique(true_arr[mask_dc])) == 2:
                    score_dc = roc_auc_score(true_arr[mask_dc], dc_arr[mask_dc])
            except Exception:
                pass
            try:
                if mask_fm.sum() >= 10 and len(np.unique(true_arr[mask_fm])) == 2:
                    score_fm = roc_auc_score(true_arr[mask_fm], fm_arr[mask_fm])
            except Exception:
                pass
        else:
            from sklearn.metrics import r2_score
            mask_dc = ~np.isnan(dc_arr)
            mask_fm = ~np.isnan(fm_arr)
            try:
                if mask_dc.sum() >= 10:
                    score_dc = r2_score(true_arr[mask_dc], dc_arr[mask_dc])
            except Exception:
                pass
            try:
                if mask_fm.sum() >= 10:
                    score_fm = r2_score(true_arr[mask_fm], fm_arr[mask_fm])
            except Exception:
                pass

        task_scores[task] = {
            "dc":   round(float(score_dc), 4) if score_dc is not None else "N/A",
            "fm4m": round(float(score_fm), 4) if score_fm is not None else "N/A",
            "n":    len(true_arr),
        }

    return {
        "name":  name,
        "label": cfg["label"],
        "task_type": cfg["task_type"],
        "metric": "AUC-ROC" if cfg["task_type"] == "classification" else "R²",
        "tasks": task_scores,
        "n_molecules": n,
    }


# ── HTML generation ────────────────────────────────────────────────────────

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
        task_list = list(r["tasks"].keys())
        # Summarize multi-task as mean
        dc_vals  = [v["dc"]   for v in r["tasks"].values() if isinstance(v["dc"],   float)]
        fm_vals  = [v["fm4m"] for v in r["tasks"].values() if isinstance(v["fm4m"], float)]
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
body {{font-family:sans-serif;background:#0f1117;color:#e2e8f0;margin:0;padding:24px}}
h1 {{color:#93c5fd;font-size:1.6rem;margin-bottom:4px}}
p.sub {{color:#64748b;font-size:0.9rem;margin-bottom:24px}}
table {{border-collapse:collapse;width:100%;font-size:0.9rem}}
th {{background:#161926;color:#94a3b8;padding:10px 14px;text-align:left;border-bottom:1px solid #2d3148}}
td {{padding:7px 14px;border-bottom:1px solid #1a1d2e}}
.badge {{display:inline-block;padding:2px 8px;border-radius:4px;font-size:0.75rem;font-weight:600}}
.deepchem {{background:#1e3a5f;color:#60a5fa}}
.fm4m {{background:#3b2060;color:#c084fc}}
.legend {{display:flex;gap:12px;margin-bottom:16px;font-size:0.85rem}}
.green {{color:#4ade80}} .yellow {{color:#fbbf24}} .red {{color:#f87171}}
</style>
</head>
<body>
<h1>{title}</h1>
<p class="sub">MoleculeNet Benchmark • {time.strftime('%Y-%m-%d %H:%M')} • {SAMPLE_N} molecules per dataset</p>
<div class="legend">
  <span class="green">■ ≥ 0.75 (good)</span>
  <span class="yellow">■ ≥ 0.50 (fair)</span>
  <span class="red">■ &lt; 0.50 (poor)</span>
</div>
<table>
<thead>
<tr>
  <th>Dataset / Task</th>
  <th>#Mols</th>
  <th><span class="badge deepchem">DeepChemUI</span></th>
  <th><span class="badge fm4m">FM4MUI</span></th>
</tr>
</thead>
<tbody>
{''.join(rows)}
</tbody>
</table>
</body>
</html>"""

    path = Path(r"C:\Users\takay\python379\DeepChem") / filename
    path.write_text(html, encoding="utf-8")
    print(f"\nSaved: {path}")
    return str(path)


# ── Entry point ────────────────────────────────────────────────────────────
CACHE_FILE = Path(r"C:\Users\takay\python379\DeepChem") / "benchmark_cache.json"


def load_cache() -> dict:
    if CACHE_FILE.exists():
        try:
            return json.load(open(CACHE_FILE, encoding="utf-8"))
        except Exception:
            pass
    return {}


def save_cache(cache: dict):
    CACHE_FILE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    import subprocess

    targets = sys.argv[1:] if len(sys.argv) > 1 else list(DATASETS.keys())

    dc_ok_global = _check_api(DEEPCHEM_API)
    fm_ok_global = _check_api(FM4M_API)
    print(f"DeepChemUI reachable: {dc_ok_global}")
    print(f"FM4MUI reachable: {fm_ok_global}")

    cache = load_cache()
    all_results = []
    for name in targets:
        if name not in DATASETS:
            print(f"Unknown: {name}")
            continue
        # Use cached result if API was down and cache exists
        if name in cache:
            cached = cache[name]
            dc_has = any(v.get("dc") != "N/A" for v in cached.get("tasks", {}).values())
            fm_has = any(v.get("fm4m") != "N/A" for v in cached.get("tasks", {}).values())
            if (not dc_ok_global or dc_has) and (not fm_ok_global or fm_has):
                print(f"\n[{name.upper()}] Using cached result")
                all_results.append(cached)
                continue
        try:
            r = benchmark_dataset(name, DATASETS[name])
            all_results.append(r)
            cache[name] = r
            save_cache(cache)
        except Exception as e:
            print(f"  [{name}] failed: {e}")

    # Full benchmark HTML
    full_path = generate_html(all_results, "Benchmark: DeepChemUI vs FM4MUI — All Datasets", "benchmark_full.html")

    # Lipo + BBBP only
    lb_results = [r for r in all_results if r["name"] in ("lipo", "bbbp")]
    lb_path = generate_html(lb_results, "Benchmark: DeepChemUI vs FM4MUI — LIPO & BBBP", "benchmark_lipo_bbbp.html")

    # Open in browser
    subprocess.Popen(["cmd", "/c", "start", full_path])
    subprocess.Popen(["cmd", "/c", "start", lb_path])
    print("\nDone! Opened both HTML files.")
