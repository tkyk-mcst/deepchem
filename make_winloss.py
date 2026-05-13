"""
全データをまとめて benchmark_full.html と winloss.html を再生成する。
"""
import json, subprocess
import numpy as np
from pathlib import Path

CACHE   = Path(r"C:\Users\takay\python379\DeepChem\benchmark_cache.json")
OUT_DIR = Path(r"C:\Users\takay\python379\DeepChem")

ORDER = ["bbbp","lipo","esol","freesolv","bace","tox21","clintox","sider","hiv"]

# FM4M scores from the original HTML run (stored here since cache FM4M is N/A)
FM4M_SCORES = {
    "bbbp":     {"p_np": 1.0000},
    "lipo":     {"exp": 0.6855},
    "esol":     {"measured log solubility in mols per litre": 0.8596},
    "freesolv": {"expt": 0.7910},
    "bace":     {"Class": 0.9784},
    "tox21":    {
        "NR-AR":0.9926,"NR-AR-LBD":1.0000,"NR-AhR":0.9076,"NR-Aromatase":0.9906,
        "NR-ER":0.9581,"NR-ER-LBD":0.9738,"NR-PPAR-gamma":1.0000,"SR-ARE":0.8076,
        "SR-ATAD5":0.9686,"SR-HSE":0.9819,"SR-MMP":0.9964,"SR-p53":1.0000,
    },
    "clintox":  {"FDA_APPROVED":1.0000,"CT_TOX":1.0000},
    "sider":    {
        "Hepatobiliary disorders":0.8450,"Metabolism and nutrition disorders":0.9433,
        "Product issues":1.0000,"Eye disorders":0.9069,"Investigations":0.8915,
        "Musculoskeletal and connective tissue disorders":0.8527,"Gastrointestinal disorders":0.9682,
        "Social circumstances":0.9440,"Immune system disorders":0.9314,
        "Reproductive system and breast disorders":0.8822,
        "Neoplasms benign, malignant and unspecified (incl cysts and polyps)":0.8579,
        "General disorders and administration site conditions":0.9014,
        "Endocrine disorders":0.9030,"Surgical and medical procedures":0.7812,
        "Vascular disorders":0.8969,"Blood and lymphatic system disorders":0.9329,
        "Skin and subcutaneous tissue disorders":0.8711,
        "Congenital, familial and genetic disorders":0.9236,
        "Infections and infestations":0.9237,
        "Respiratory, thoracic and mediastinal disorders":0.8716,
        "Psychiatric disorders":0.8651,"Renal and urinary disorders":0.8115,
        "Pregnancy, puerperium and perinatal conditions":0.8811,
        "Ear and labyrinth disorders":0.8801,"Cardiac disorders":0.8843,
        "Nervous system disorders":0.9673,
        "Injury, poisoning and procedural complications":0.8226,
    },
    "hiv":      {"HIV_active":0.9347},
}

LABELS = {
    "bbbp":"BBBP","lipo":"Lipophilicity (LogD)","esol":"ESOL (LogS)",
    "freesolv":"FreeSolv (ΔG)","bace":"BACE","tox21":"Tox21",
    "clintox":"ClinTox","sider":"SIDER","hiv":"HIV",
}
TASK_TYPE = {
    "bbbp":"classification","lipo":"regression","esol":"regression",
    "freesolv":"regression","bace":"classification","tox21":"classification",
    "clintox":"classification","sider":"classification","hiv":"classification",
}
METRIC = {k: ("AUC-ROC" if v=="classification" else "R²") for k,v in TASK_TYPE.items()}


def load_data():
    cache = json.loads(CACHE.read_text(encoding="utf-8"))
    rows = []
    for key in ORDER:
        dc_tasks = cache.get(key, {}).get("tasks", {})
        fm_tasks = FM4M_SCORES.get(key, {})
        n_mol   = cache.get(key, {}).get("n_molecules", 100)

        merged = {}
        all_tasks = set(dc_tasks) | set(fm_tasks)
        for t in all_tasks:
            dc  = dc_tasks.get(t, {}).get("dc",   "N/A") if t in dc_tasks else "N/A"
            fm  = fm_tasks.get(t, "N/A")
            n   = dc_tasks.get(t, {}).get("n", n_mol)    if t in dc_tasks else n_mol
            merged[t] = {"dc": dc, "fm4m": fm, "n": n}

        dc_vals = [v["dc"]   for v in merged.values() if isinstance(v["dc"],   float)]
        fm_vals = [v["fm4m"] for v in merged.values() if isinstance(v["fm4m"], float)]
        mean_dc = round(float(np.mean(dc_vals)), 4) if dc_vals else None
        mean_fm = round(float(np.mean(fm_vals)), 4) if fm_vals else None

        rows.append({
            "key": key, "label": LABELS[key],
            "metric": METRIC[key], "task_type": TASK_TYPE[key],
            "tasks": merged, "n_molecules": n_mol,
            "mean_dc": mean_dc, "mean_fm": mean_fm,
        })
    return rows


# ── HTML helpers ──────────────────────────────────────────────────────────────

def _cell(v, bold=False):
    if v is None or v == "N/A":
        return '<td style="color:#4b5563">N/A</td>'
    f = float(v)
    color = "#4ade80" if f >= 0.75 else ("#fbbf24" if f >= 0.5 else "#f87171")
    weight = "font-weight:700;" if bold else ""
    return f'<td style="color:{color};{weight}">{f:.4f}</td>'


def _winner_badge(dc, fm):
    if dc is None or fm is None:
        return ""
    if dc > fm + 0.005:
        return ' <span style="background:#1d4ed8;color:#fff;border-radius:4px;padding:1px 6px;font-size:11px">DC</span>'
    if fm > dc + 0.005:
        return ' <span style="background:#7c3aed;color:#fff;border-radius:4px;padding:1px 6px;font-size:11px">FM4M</span>'
    return ' <span style="background:#374151;color:#9ca3af;border-radius:4px;padding:1px 6px;font-size:11px">—</span>'


# ── Generate benchmark_full.html ──────────────────────────────────────────────

def gen_full(rows):
    body = ""
    for r in rows:
        badge = _winner_badge(r["mean_dc"], r["mean_fm"])
        body += f"""
        <tr style="background:#1e2130">
          <td style="font-weight:700;color:#93c5fd">{r['label']}{badge}</td>
          <td style="color:#6b7280">{r['metric']}</td>
          <td>{r['n_molecules']}</td>
          {_cell(r['mean_dc'], bold=True)}
          {_cell(r['mean_fm'], bold=True)}
        </tr>"""
        for task, s in r["tasks"].items():
            body += f"""
        <tr>
          <td style="padding-left:20px;color:#6b7280;font-size:13px">{task}</td>
          <td></td>
          <td style="color:#6b7280">{s['n']}</td>
          {_cell(s['dc'])}
          {_cell(s['fm4m'])}
        </tr>"""

    html = f"""<!DOCTYPE html><html lang="ja"><head><meta charset="utf-8">
<title>Benchmark: DeepChemUI vs FM4MUI</title>
<style>
body{{background:#0f1117;color:#e0e0e0;font-family:'Segoe UI',sans-serif;margin:0;padding:24px}}
h1{{color:#93c5fd;margin-bottom:4px}}
.sub{{color:#6b7280;margin-bottom:24px;font-size:13px}}
table{{border-collapse:collapse;width:100%;max-width:960px}}
th{{background:#1e2130;color:#93c5fd;padding:10px 14px;text-align:left;border-bottom:2px solid #374151}}
td{{padding:7px 14px;border-bottom:1px solid #1a1f2e}}
tr:hover td{{background:#1a1f2e}}
.legend{{margin-top:16px;font-size:12px;color:#6b7280}}
</style></head><body>
<h1>🧪 Molecular Property Prediction Benchmark</h1>
<p class="sub">DeepChemUI (ECFP4 + MultitaskNet) vs FM4MUI (MolFormer-XL embeddings) &nbsp;|&nbsp; MoleculeNet 9 datasets</p>
<table>
<thead><tr>
  <th>Dataset / Task</th><th>Metric</th><th>N</th>
  <th>DeepChemUI</th><th>FM4MUI</th>
</tr></thead>
<tbody>{body}</tbody>
</table>
<div class="legend">
  <span style="color:#4ade80">&#9632; &ge;0.75</span>&nbsp;
  <span style="color:#fbbf24">&#9632; &ge;0.50</span>&nbsp;
  <span style="color:#f87171">&#9632; &lt;0.50</span>&nbsp;&nbsp;
  Badge: winner per dataset (diff &gt; 0.005)
</div>
</body></html>"""

    p = OUT_DIR / "benchmark_full.html"
    p.write_text(html, encoding="utf-8")
    print(f"  -> {p}")


# ── Generate winloss.html ─────────────────────────────────────────────────────

def gen_winloss(rows):
    dc_wins = fm_wins = ties = 0
    dc_total = fm_total = 0.0
    dc_count = fm_count = 0

    tbl = ""
    for r in rows:
        dc, fm = r["mean_dc"], r["mean_fm"]
        if dc is None or fm is None:
            result = "N/A"
            badge = '<td style="color:#4b5563">N/A</td>'
        elif dc > fm + 0.005:
            result = "DeepChem"
            badge = '<td style="color:#60a5fa;font-weight:700">✅ DeepChemUI</td>'
            dc_wins += 1
        elif fm > dc + 0.005:
            result = "FM4M"
            badge = '<td style="color:#a78bfa;font-weight:700">✅ FM4MUI</td>'
            fm_wins += 1
        else:
            result = "tie"
            badge = '<td style="color:#9ca3af">— Tie</td>'
            ties += 1

        if dc is not None:
            dc_total += dc; dc_count += 1
        if fm is not None:
            fm_total += fm; fm_count += 1

        diff = f"{fm-dc:+.4f}" if dc is not None and fm is not None else "—"
        diff_color = "#a78bfa" if dc is not None and fm is not None and fm > dc else "#60a5fa"

        tbl += f"""<tr>
          <td style="font-weight:600;color:#e5e7eb">{r['label']}</td>
          <td style="color:#6b7280">{r['metric']}</td>
          {_cell(dc, bold=True)}
          {_cell(fm, bold=True)}
          <td style="color:{diff_color};font-weight:600">{diff}</td>
          {badge}
        </tr>"""

    avg_dc = dc_total / dc_count if dc_count else 0
    avg_fm = fm_total / fm_count if fm_count else 0
    overall = "FM4MUI" if avg_fm > avg_dc else "DeepChemUI"
    overall_color = "#a78bfa" if avg_fm > avg_dc else "#60a5fa"

    summary = f"""
    <tr style="background:#1e2130;border-top:2px solid #374151">
      <td style="font-weight:700;color:#93c5fd">AVERAGE</td>
      <td></td>
      <td style="color:#60a5fa;font-weight:700">{avg_dc:.4f}</td>
      <td style="color:#a78bfa;font-weight:700">{avg_fm:.4f}</td>
      <td style="color:{overall_color};font-weight:700">{avg_fm-avg_dc:+.4f}</td>
      <td style="color:{overall_color};font-weight:700">🏆 {overall}</td>
    </tr>"""

    scoreboard = f"""
    <div style="display:flex;gap:32px;margin-bottom:28px">
      <div style="background:#1e2130;border-radius:12px;padding:20px 32px;text-align:center">
        <div style="color:#60a5fa;font-size:48px;font-weight:800">{dc_wins}</div>
        <div style="color:#93c5fd;font-size:14px">DeepChemUI 勝利</div>
      </div>
      <div style="background:#1e2130;border-radius:12px;padding:20px 32px;text-align:center">
        <div style="color:#a78bfa;font-size:48px;font-weight:800">{fm_wins}</div>
        <div style="color:#c4b5fd;font-size:14px">FM4MUI 勝利</div>
      </div>
      <div style="background:#1e2130;border-radius:12px;padding:20px 32px;text-align:center">
        <div style="color:#9ca3af;font-size:48px;font-weight:800">{ties}</div>
        <div style="color:#9ca3af;font-size:14px">引き分け</div>
      </div>
    </div>"""

    html = f"""<!DOCTYPE html><html lang="ja"><head><meta charset="utf-8">
<title>勝敗表: DeepChemUI vs FM4MUI</title>
<style>
body{{background:#0f1117;color:#e0e0e0;font-family:'Segoe UI',sans-serif;margin:0;padding:32px}}
h1{{color:#93c5fd;margin-bottom:4px}}
.sub{{color:#6b7280;margin-bottom:24px;font-size:13px}}
table{{border-collapse:collapse;width:100%;max-width:860px}}
th{{background:#1e2130;color:#93c5fd;padding:10px 16px;text-align:left;border-bottom:2px solid #374151}}
td{{padding:10px 16px;border-bottom:1px solid #1a1f2e}}
tr:hover td{{background:#1a1f2e}}
</style></head><body>
<h1>🏆 勝敗表 — DeepChemUI vs FM4MUI</h1>
<p class="sub">MoleculeNet 9 データセット | 勝敗基準: 平均スコア差 &gt; 0.005</p>
{scoreboard}
<table>
<thead><tr>
  <th>データセット</th><th>指標</th>
  <th style="color:#60a5fa">DeepChemUI</th>
  <th style="color:#a78bfa">FM4MUI</th>
  <th>FM4M − DC</th>
  <th>勝者</th>
</tr></thead>
<tbody>
{tbl}
{summary}
</tbody>
</table>
<p style="margin-top:20px;color:#4b5563;font-size:12px">
  DeepChemUI: ECFP4 (radius=4, 2048bit) + MultitaskClassifier/Regressor<br>
  FM4MUI: IBM MolFormer-XL 768次元埋め込み + Ridge/LogisticRegression
</p>
</body></html>"""

    p = OUT_DIR / "winloss.html"
    p.write_text(html, encoding="utf-8")
    print(f"  -> {p}")
    return dc_wins, fm_wins, ties, avg_dc, avg_fm


def main():
    rows = load_data()
    print("Generating benchmark_full.html ...")
    gen_full(rows)
    print("Generating winloss.html ...")
    dc_wins, fm_wins, ties, avg_dc, avg_fm = gen_winloss(rows)

    print(f"\n=== 勝敗結果 ===")
    print(f"  DeepChemUI 勝利: {dc_wins}/9")
    print(f"  FM4MUI     勝利: {fm_wins}/9")
    print(f"  引き分け:        {ties}/9")
    print(f"  平均スコア: DC={avg_dc:.4f}  FM4M={avg_fm:.4f}")

    subprocess.Popen(["cmd", "/c", "start", "", str(OUT_DIR / "winloss.html")])
    subprocess.Popen(["cmd", "/c", "start", "", str(OUT_DIR / "benchmark_full.html")])
    print("Opened both HTMLs.")


if __name__ == "__main__":
    main()
