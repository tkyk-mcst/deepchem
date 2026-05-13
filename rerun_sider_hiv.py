"""
DeepChem SIDER と HIV だけ再ベンチマーク。
SIDER: 200 molecules, HIV: 500 molecules (大サンプルで確認)
"""
import json, random, requests
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.metrics import roc_auc_score

DC_API     = "http://localhost:8282"
_BASE      = Path(__file__).parent
DATA_BASE  = _BASE / "MS_prediction dataset"
CACHE_FILE = _BASE / "benchmark_cache.json"

TARGETS = {
    "sider": {
        "input":  DATA_BASE/"sider/sider_input.csv",
        "output": DATA_BASE/"sider/sider_output.csv",
        "smiles_col": "smiles",
        "label": "SIDER",
        "n": 200,
    },
    "hiv": {
        "input":  DATA_BASE/"HIV/HIV_input.csv",
        "output": DATA_BASE/"HIV/HIV_output.csv",
        "smiles_col": "smiles",
        "label": "HIV",
        "n": 500,
    },
}


def batch_predict(smiles_list):
    r = requests.post(f"{DC_API}/predict/batch",
                      json={"smiles_list": smiles_list}, timeout=300)
    r.raise_for_status()
    data = r.json()
    return data.get("results", data) if isinstance(data, dict) else data


def get_sider_pred(result, task_col):
    sider = result.get("predictions", {}).get("sider", {})
    entry = sider.get(task_col, {})
    if isinstance(entry, dict):
        return entry.get("probability")
    return None


def get_hiv_pred(result):
    hiv = result.get("predictions", {}).get("hiv", {})
    if isinstance(hiv, dict):
        return hiv.get("probability")
    return None


def run(name, cfg):
    print(f"\n=== {name.upper()} (n={cfg['n']}) ===")
    df_in  = pd.read_csv(cfg["input"])
    df_out = pd.read_csv(cfg["output"])
    tasks  = list(df_out.columns)

    n   = min(cfg["n"], len(df_in))
    idx = random.Random(42).sample(range(len(df_in)), n)
    smiles_list  = [df_in[cfg["smiles_col"]].iloc[i] for i in idx]
    labels_mat   = df_out.values[idx]

    # Batch calls
    BATCH = 50
    results = []
    for start in range(0, n, BATCH):
        batch = smiles_list[start:start+BATCH]
        print(f"  batch {start+len(batch)}/{n} …")
        results.extend(batch_predict(batch))

    # Collect per task
    true_pt = {t: [] for t in tasks}
    pred_pt = {t: [] for t in tasks}
    for j, (res, label_row) in enumerate(zip(results, labels_mat)):
        for t_idx, task in enumerate(tasks):
            try:
                tv = float(label_row[t_idx])
            except (TypeError, ValueError):
                continue
            if np.isnan(tv):
                continue
            if name == "sider":
                pv = get_sider_pred(res, task)
            else:  # hiv
                pv = get_hiv_pred(res)
            true_pt[task].append(tv)
            pred_pt[task].append(pv)

    # Score
    task_scores = {}
    for task in tasks:
        ta = np.array(true_pt[task])
        pa = np.array([p if p is not None else np.nan for p in pred_pt[task]])
        mask = ~np.isnan(pa)
        if mask.sum() < 10 or len(np.unique(ta[mask])) < 2:
            print(f"  [{task}] skipped (n={mask.sum()}, classes={np.unique(ta[mask])})")
            continue
        auc = roc_auc_score(ta[mask], pa[mask])
        task_scores[task] = round(float(auc), 4)
        print(f"  {task}: AUC={auc:.4f}  (n={mask.sum()}, pos={int(ta[mask].sum())})")

    if task_scores:
        mean_auc = round(np.mean(list(task_scores.values())), 4)
        print(f"  → Mean AUC: {mean_auc}")
    else:
        print("  → No valid tasks")
    return task_scores, n


def main():
    cache = json.loads(CACHE_FILE.read_text(encoding="utf-8"))

    for name, cfg in TARGETS.items():
        task_scores, n = run(name, cfg)
        # Update cache
        new_tasks = {}
        for task, auc in task_scores.items():
            old_fm = cache.get(name, {}).get("tasks", {}).get(task, {}).get("fm4m", "N/A")
            new_tasks[task] = {"dc": auc, "fm4m": old_fm, "n": n}
        if name in cache:
            cache[name]["tasks"] = new_tasks
            cache[name]["n_molecules"] = n
        CACHE_FILE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  Cache updated for {name}")

    print("\nDone.")


if __name__ == "__main__":
    main()
