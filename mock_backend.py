"""
Mock backend for MolPredict Flutter app.
Uses RDKit for real descriptor calculations.
ML predictions are mock values (no DeepChem needed).
Run: python mock_backend.py
"""
import math, random, io, json
from contextlib import asynccontextmanager
from typing import List, Optional

import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

from rdkit import Chem
from rdkit.Chem import Descriptors, rdMolDescriptors, QED, AllChem, rdDepictor
from rdkit.Chem.Draw import rdMolDraw2D
from rdkit.Chem import FilterCatalog

# ── PAINS catalog ──────────────────────────────────────────────────────────
_pains_cat = None
_brenk_cat = None

def get_pains():
    global _pains_cat
    if _pains_cat is None:
        p = FilterCatalog.FilterCatalogParams()
        p.AddCatalog(FilterCatalog.FilterCatalogParams.FilterCatalogs.PAINS)
        _pains_cat = FilterCatalog.FilterCatalog(p)
    return _pains_cat

def get_brenk():
    global _brenk_cat
    if _brenk_cat is None:
        p = FilterCatalog.FilterCatalogParams()
        p.AddCatalog(FilterCatalog.FilterCatalogParams.FilterCatalogs.BRENK)
        _brenk_cat = FilterCatalog.FilterCatalog(p)
    return _brenk_cat

@asynccontextmanager
async def lifespan(app):
    get_pains(); get_brenk()
    print("[OK] Mock backend ready on http://localhost:8080")
    yield

app = FastAPI(title="MolPredict Mock API", version="2.0.0-mock", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── Helpers ────────────────────────────────────────────────────────────────

def rdkit_descriptors(mol):
    return {
        "molecular_weight": round(Descriptors.MolWt(mol), 2),
        "exact_mw":         round(Descriptors.ExactMolWt(mol), 4),
        "logp":             round(Descriptors.MolLogP(mol), 2),
        "hbd":              int(rdMolDescriptors.CalcNumHBD(mol)),
        "hba":              int(rdMolDescriptors.CalcNumHBA(mol)),
        "tpsa":             round(Descriptors.TPSA(mol), 2),
        "rotatable_bonds":  int(rdMolDescriptors.CalcNumRotatableBonds(mol)),
        "aromatic_rings":   int(rdMolDescriptors.CalcNumAromaticRings(mol)),
        "heavy_atoms":      mol.GetNumHeavyAtoms(),
        "rings":            int(rdMolDescriptors.CalcNumRings(mol)),
        "stereo_centers":   len(Chem.FindMolChiralCenters(mol, includeUnassigned=True)),
        "molecular_formula": rdMolDescriptors.CalcMolFormula(mol),
        "fsp3":             round(float(rdMolDescriptors.CalcFractionCSP3(mol)), 3),
    }

def drug_likeness(mol):
    d = rdkit_descriptors(mol)
    checks = {
        "mw_ok":   d["molecular_weight"] <= 500,
        "logp_ok": d["logp"] <= 5,
        "hbd_ok":  d["hbd"] <= 5,
        "hba_ok":  d["hba"] <= 10,
    }
    violations = sum(1 for v in checks.values() if not v)
    veber = d["rotatable_bonds"] <= 10 and d["tpsa"] <= 140
    try: qed = round(float(QED.qed(mol)), 3)
    except: qed = None
    return {**checks, "violations": violations, "drug_like": violations <= 1, "veber_ok": veber, "qed": qed}

def get_alerts(mol):
    pains = [m.GetDescription() for m in get_pains().GetMatches(mol)]
    brenk = [m.GetDescription() for m in get_brenk().GetMatches(mol)]
    return {"pains": pains, "brenk": brenk, "has_alerts": bool(pains or brenk)}

def mock_predictions(mol):
    """Generate plausible mock ML predictions based on descriptors."""
    d = rdkit_descriptors(mol)
    mw   = d["molecular_weight"]
    logp = d["logp"]
    tpsa = d["tpsa"]
    hbd  = d["hbd"]

    # Solubility: approx by logP (Yalkowsky eq)
    log_s = 0.5 - logp - 0.01 * (mw - 68)
    log_s = round(max(-10.0, min(2.0, log_s + random.gauss(0, 0.3))), 3)
    sol_label = ("Highly Soluble" if log_s > -1 else
                 "Soluble" if log_s > -3 else
                 "Moderately Soluble" if log_s > -5 else "Poorly Soluble")

    # BBBP: small, lipophilic → more permeable
    bbbp = 1 / (1 + math.exp(-(0.3 * logp - 0.01 * tpsa - 0.004 * mw + 0.5)))
    bbbp = round(min(0.99, max(0.01, bbbp + random.gauss(0, 0.05))), 3)

    # HIV: random but biased toward inactive
    hiv = round(max(0.01, min(0.99, random.betavariate(1.5, 8))), 3)

    # Tox21 tasks
    tox21_tasks = [
        "NR-AR", "NR-AR-LBD", "NR-AhR", "NR-Aromatase",
        "NR-ER", "NR-ER-LBD", "NR-PPAR-gamma",
        "SR-ARE", "SR-ATAD5", "SR-HSE", "SR-MMP", "SR-p53"
    ]
    tox21 = {}
    for t in tox21_tasks:
        p = round(max(0.01, min(0.99, random.betavariate(1, 5))), 3)
        tox21[t] = {"probability": p, "label": "Toxic" if p >= 0.5 else "Non-toxic"}

    # ClinTox
    ct_p = round(max(0.01, min(0.99, random.betavariate(1, 6))), 3)
    fda_p = round(1.0 - ct_p + random.gauss(0, 0.05), 3)
    fda_p = max(0.01, min(0.99, fda_p))
    clintox = {
        "CT_TOX": {"probability": ct_p, "label": "Positive" if ct_p >= 0.5 else "Negative"},
        "FDA_APPROVED": {"probability": fda_p, "label": "Positive" if fda_p >= 0.5 else "Negative"},
    }

    return {
        "solubility": {
            "logS": log_s, "unit": "log(mol/L)", "label": sol_label,
            "uncertainty": {"std": round(abs(random.gauss(0, 0.4)), 3)},
        },
        "bbbp": {
            "probability": bbbp,
            "label": "Permeable" if bbbp >= 0.5 else "Not Permeable",
            "uncertainty": {"variance": round(abs(random.gauss(0, 0.02)), 4)},
        },
        "hiv": {
            "probability": hiv,
            "label": "Active" if hiv >= 0.5 else "Inactive",
            "uncertainty": {"variance": round(abs(random.gauss(0, 0.02)), 4)},
        },
        "tox21": tox21,
        "clintox": clintox,
    }

def mol_to_svg(mol, w=300, h=200):
    rdDepictor.Compute2DCoords(mol)
    d = rdMolDraw2D.MolDraw2DSVG(w, h)
    d.drawOptions().addStereoAnnotation = True
    d.DrawMolecule(mol)
    d.FinishDrawing()
    return d.GetDrawingText()

def mol_to_png(mol, w=400, h=300):
    rdDepictor.Compute2DCoords(mol)
    d = rdMolDraw2D.MolDraw2DCairo(w, h)
    d.DrawMolecule(mol)
    d.FinishDrawing()
    return d.GetDrawingText()

def full_predict(smiles):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None:
        raise ValueError(f"Invalid SMILES: {smiles!r}")
    return {
        "smiles": smiles,
        "canonical_smiles": Chem.MolToSmiles(mol),
        "valid": True,
        "descriptors": rdkit_descriptors(mol),
        "drug_likeness": drug_likeness(mol),
        "alerts": get_alerts(mol),
        "predictions": mock_predictions(mol),
        "models_loaded": ["solubility", "bbbp", "tox21", "clintox", "hiv"],
    }

# ── Sample molecules ───────────────────────────────────────────────────────
SAMPLES = [
    {"name": "Aspirin",      "smiles": "CC(=O)Oc1ccccc1C(=O)O",            "description": "痛み止め・解熱剤"},
    {"name": "Caffeine",     "smiles": "Cn1c(=O)c2c(ncn2C)n(c1=O)C",       "description": "コーヒーの覚醒剤"},
    {"name": "Ibuprofen",    "smiles": "CC(C)Cc1ccc(cc1)C(C)C(=O)O",       "description": "抗炎症薬"},
    {"name": "Paracetamol",  "smiles": "CC(=O)Nc1ccc(O)cc1",               "description": "解熱・鎮痛剤"},
    {"name": "Penicillin G", "smiles": "CC1(C)SC2C(NC(=O)Cc3ccccc3)C(=O)N2C1C(=O)O", "description": "抗生物質"},
    {"name": "Dopamine",     "smiles": "NCCc1ccc(O)c(O)c1",                "description": "神経伝達物質"},
    {"name": "Serotonin",    "smiles": "NCCc1c[nH]c2ccc(O)cc12",           "description": "幸福ホルモン"},
    {"name": "Glucose",      "smiles": "OC[C@H]1OC(O)[C@H](O)[C@@H](O)[C@@H]1O", "description": "単純糖"},
    {"name": "Cholesterol",  "smiles": "CC(C)CCC[C@@H](C)[C@H]1CC[C@H]2[C@@H]3CC=C4C[C@@H](O)CC[C@]4(C)[C@H]3CC[C@]12C", "description": "ステロイド"},
    {"name": "Ethanol",      "smiles": "CCO",                               "description": "アルコール"},
    {"name": "Sildenafil",   "smiles": "CCCC1=NN(C)C(=C1C(=O)NCC2=CC(=CC=C2OCC)S(=O)(=O)N3CCN(CC3)C)C4=CC=CC=C4", "description": "バイアグラ"},
    {"name": "Metformin",    "smiles": "CN(C)C(=N)NC(=N)N",                "description": "糖尿病治療薬"},
]

# ── Request models ─────────────────────────────────────────────────────────
class PredictReq(BaseModel): smiles: str
class BatchReq(BaseModel):   smiles_list: List[str]
class CompareReq(BaseModel): smiles1: str; smiles2: str

# ── Endpoints ──────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "version": "2.0.0-mock",
            "models_loaded": ["solubility", "bbbp", "tox21", "clintox", "hiv"]}

@app.get("/samples")
def samples(): return {"molecules": SAMPLES}

@app.post("/predict")
def predict(req: PredictReq):
    try: return full_predict(req.smiles.strip())
    except ValueError as e: raise HTTPException(400, str(e))

@app.post("/predict/batch")
def predict_batch(req: BatchReq):
    if len(req.smiles_list) > 100:
        raise HTTPException(400, "Max 100 molecules per batch")
    results = []
    for s in req.smiles_list:
        try: results.append(full_predict(s.strip()))
        except Exception as e: results.append({"smiles": s, "valid": False, "error": str(e)})
    return {"count": len(results), "results": results}

@app.get("/molecule/image")
def mol_image(smiles: str = Query(...), width: int = Query(300), height: int = Query(200)):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None: raise HTTPException(400, "Invalid SMILES")
    return Response(mol_to_svg(mol, width, height), media_type="image/svg+xml")

@app.get("/molecule/png")
def mol_png(smiles: str = Query(...), width: int = Query(400), height: int = Query(300)):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None: raise HTTPException(400, "Invalid SMILES")
    return Response(mol_to_png(mol, width, height), media_type="image/png")

@app.get("/molecule/3d")
def mol_3d(smiles: str = Query(...)):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None: raise HTTPException(400, "Invalid SMILES")
    mol = Chem.AddHs(mol)
    AllChem.EmbedMolecule(mol, AllChem.ETKDGv3())
    try: AllChem.MMFFOptimizeMolecule(mol)
    except: pass
    from rdkit.Chem import SDWriter
    buf = io.StringIO()
    w = SDWriter(buf); w.write(mol); w.close()
    return Response(buf.getvalue(), media_type="chemical/x-mdl-sdfile")

@app.get("/molecule/standardize")
def mol_standardize(smiles: str = Query(...)):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None: raise HTTPException(400, "Invalid SMILES")
    return {
        "input_smiles": smiles,
        "canonical_smiles": Chem.MolToSmiles(mol),
        "molecular_formula": rdMolDescriptors.CalcMolFormula(mol),
        "inchi": None, "inchikey": None,
    }

@app.get("/molecule/similarity")
def mol_similarity(smiles1: str = Query(...), smiles2: str = Query(...)):
    m1 = Chem.MolFromSmiles(smiles1); m2 = Chem.MolFromSmiles(smiles2)
    if not m1: raise HTTPException(400, f"Invalid: {smiles1}")
    if not m2: raise HTTPException(400, f"Invalid: {smiles2}")
    from rdkit import DataStructs
    fp1 = AllChem.GetMorganFingerprintAsBitVect(m1, 2, 2048)
    fp2 = AllChem.GetMorganFingerprintAsBitVect(m2, 2, 2048)
    sim = round(float(DataStructs.TanimotoSimilarity(fp1, fp2)), 4)
    label = ("Very Similar" if sim >= 0.85 else "Similar" if sim >= 0.65 else
             "Somewhat Similar" if sim >= 0.40 else "Dissimilar")
    return {"smiles1": smiles1, "smiles2": smiles2, "tanimoto_similarity": sim, "interpretation": label}

@app.post("/molecule/compare")
def mol_compare(req: CompareReq):
    p1 = full_predict(req.smiles1.strip())
    p2 = full_predict(req.smiles2.strip())
    m1 = Chem.MolFromSmiles(req.smiles1); m2 = Chem.MolFromSmiles(req.smiles2)
    from rdkit import DataStructs
    fp1 = AllChem.GetMorganFingerprintAsBitVect(m1, 2, 2048)
    fp2 = AllChem.GetMorganFingerprintAsBitVect(m2, 2, 2048)
    sim = round(float(DataStructs.TanimotoSimilarity(fp1, fp2)), 4)
    return {"molecule_1": p1, "molecule_2": p2,
            "similarity": {"tanimoto_similarity": sim}}

@app.get("/molecule/alerts")
def mol_alerts(smiles: str = Query(...)):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None: raise HTTPException(400, "Invalid SMILES")
    return get_alerts(mol)

@app.get("/molecule/variants")
def mol_variants(smiles: str = Query(...), n: int = Query(6)):
    mol = Chem.MolFromSmiles(smiles)
    if mol is None: raise HTTPException(400, "Invalid SMILES")
    substitutions = [
        ("[c:1][H]>>[c:1]F",   "F-substituted"),
        ("[c:1][H]>>[c:1]Cl",  "Cl-substituted"),
        ("[c:1][H]>>[c:1]OC",  "methoxy"),
        ("[c:1][H]>>[c:1]N",   "amino"),
        ("[c:1][H]>>[c:1]C",   "methyl"),
        ("[c:1][H]>>[c:1]C#N", "cyano"),
    ]
    base = Chem.MolToSmiles(mol)
    variants = []
    for smarts, label in substitutions:
        try:
            rxn = AllChem.ReactionFromSmarts(smarts)
            prods = rxn.RunReactants((mol,))
            if prods:
                pm = prods[0][0]; Chem.SanitizeMol(pm)
                smi = Chem.MolToSmiles(pm)
                if smi != base and not any(v["smiles"] == smi for v in variants):
                    variants.append({"smiles": smi, "modification": label})
                    if len(variants) >= n: break
        except: continue
    return {"base_smiles": smiles, "variants": variants}

@app.get("/pubchem/search")
async def pubchem_search(name: str = Query(...)):
    try:
        url = (f"https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/{name}"
               "/property/IsomericSMILES,CanonicalSMILES,MolecularFormula,MolecularWeight,IUPACName/JSON")
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.get(url)
        if r.status_code == 404:
            raise HTTPException(404, f"'{name}' not found in PubChem")
        r.raise_for_status()
        props = r.json()["PropertyTable"]["Properties"]
        return {"query": name, "results": [
            {
                "cid": p.get("CID"),
                # PubChem returns "IsomericSMILES", "CanonicalSMILES", or just "SMILES"
                "smiles": p.get("IsomericSMILES") or p.get("CanonicalSMILES") or p.get("SMILES"),
                "formula": p.get("MolecularFormula"),
                "mw": p.get("MolecularWeight"),
                "iupac": p.get("IUPACName"),
            }
            for p in props[:5]
        ]}
    except HTTPException: raise
    except httpx.TimeoutException: raise HTTPException(504, "PubChem timeout")
    except Exception as e: raise HTTPException(500, f"PubChem error: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8282)
