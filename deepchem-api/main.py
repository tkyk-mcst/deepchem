"""
DeepChem Molecular Properties API — Extended
Endpoints:
  POST /predict              SMILES → full prediction
  POST /predict/batch        list of SMILES → batch predictions
  GET  /molecule/image       SMILES → 2D SVG
  GET  /molecule/png         SMILES → 2D PNG
  GET  /molecule/3d          SMILES → 3D SDF
  GET  /molecule/standardize SMILES → canonical / InChI / formula
  GET  /molecule/similarity  smiles1 + smiles2 → Tanimoto
  POST /molecule/compare     smiles1 + smiles2 → side-by-side predictions
  GET  /molecule/alerts      SMILES → PAINS / Brenk alerts
  GET  /molecule/variants    SMILES → analog suggestions
  GET  /pubchem/search       name → SMILES (PubChem proxy)
  GET  /samples              sample molecules
  GET  /health               health check
  GET  /                     demo frontend
"""

import logging
import httpx
from contextlib import asynccontextmanager
from typing import List

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from predictor import MoleculePredictor

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

predictor = MoleculePredictor()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Loading DeepChem models...")
    predictor.initialize()
    logger.info("Ready.")
    yield


app = FastAPI(
    title="DeepChem Molecular Properties API",
    description="Molecular property prediction powered by DeepChem and RDKit",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

# ------------------------------------------------------------------
# Sample molecules
# ------------------------------------------------------------------

SAMPLE_MOLECULES = [
    {"name": "Aspirin",      "smiles": "CC(=O)Oc1ccccc1C(=O)O",                           "description": "痛み止め・解熱剤"},
    {"name": "Caffeine",     "smiles": "Cn1c(=O)c2c(ncn2C)n(c1=O)C",                      "description": "コーヒーの覚醒剤"},
    {"name": "Ibuprofen",    "smiles": "CC(C)Cc1ccc(cc1)C(C)C(=O)O",                      "description": "抗炎症薬"},
    {"name": "Paracetamol",  "smiles": "CC(=O)Nc1ccc(O)cc1",                              "description": "解熱・鎮痛剤"},
    {"name": "Penicillin G", "smiles": "CC1(C)SC2C(NC(=O)Cc3ccccc3)C(=O)N2C1C(=O)O",    "description": "抗生物質"},
    {"name": "Dopamine",     "smiles": "NCCc1ccc(O)c(O)c1",                               "description": "神経伝達物質"},
    {"name": "Serotonin",    "smiles": "NCCc1c[nH]c2ccc(O)cc12",                          "description": "幸福ホルモン"},
    {"name": "Glucose",      "smiles": "OC[C@H]1OC(O)[C@H](O)[C@@H](O)[C@@H]1O",        "description": "単純糖"},
    {"name": "Cholesterol",  "smiles": "CC(C)CCC[C@@H](C)[C@H]1CC[C@H]2[C@@H]3CC=C4C[C@@H](O)CC[C@]4(C)[C@H]3CC[C@]12C", "description": "ステロイド"},
    {"name": "Ethanol",      "smiles": "CCO",                                              "description": "アルコール"},
    {"name": "Sildenafil",   "smiles": "CCCC1=NN(C)C(=C1C(=O)NCC2=CC(=CC=C2OCC)S(=O)(=O)N3CCN(CC3)C)C4=CC=CC=C4", "description": "バイアグラ"},
    {"name": "Metformin",    "smiles": "CN(C)C(=N)NC(=N)N",                               "description": "糖尿病治療薬"},
]

# ------------------------------------------------------------------
# Request / Response models
# ------------------------------------------------------------------

class PredictRequest(BaseModel):
    smiles: str
    model_config = {"json_schema_extra": {"example": {"smiles": "CC(=O)Oc1ccccc1C(=O)O"}}}


class BatchPredictRequest(BaseModel):
    smiles_list: List[str]
    model_config = {"json_schema_extra": {"example": {"smiles_list": ["CC(=O)Oc1ccccc1C(=O)O", "CCO"]}}}


class CompareRequest(BaseModel):
    smiles1: str
    smiles2: str
    model_config = {"json_schema_extra": {"example": {
        "smiles1": "CC(=O)Oc1ccccc1C(=O)O",
        "smiles2": "CC(=O)Nc1ccc(O)cc1"
    }}}


# ------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------

@app.get("/", include_in_schema=False)
async def serve_frontend():
    return FileResponse("static/index.html")


@app.get("/health", tags=["System"])
async def health():
    return {
        "status": "ok",
        "version": "2.0.0",
        "models_loaded": list(predictor.models.keys()),
    }


@app.get("/samples", tags=["Molecules"])
async def get_samples():
    return {"molecules": SAMPLE_MOLECULES}


# ── Prediction ──────────────────────────────────────────────────────────

@app.post("/predict", tags=["Prediction"])
async def predict(request: PredictRequest):
    """Single SMILES → full molecular property prediction."""
    try:
        result = predictor.predict(request.smiles.strip())
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception("Prediction failed")
        raise HTTPException(status_code=500, detail="Internal prediction error")


@app.post("/predict/batch", tags=["Prediction"])
async def predict_batch(request: BatchPredictRequest):
    """Multiple SMILES → batch predictions (max 100)."""
    if len(request.smiles_list) > 100:
        raise HTTPException(status_code=400, detail="Maximum 100 molecules per batch")
    try:
        results = predictor.predict_batch(request.smiles_list)
        return {"count": len(results), "results": results}
    except Exception as e:
        logger.exception("Batch prediction failed")
        raise HTTPException(status_code=500, detail="Batch prediction error")


# ── Molecule utilities ──────────────────────────────────────────────────

@app.get("/molecule/image", tags=["Molecules"])
async def molecule_image(
    smiles: str = Query(..., description="SMILES string"),
    width:  int = Query(300, ge=100, le=800),
    height: int = Query(200, ge=100, le=800),
):
    """Return 2D SVG structure image."""
    svg = predictor.get_svg(smiles.strip(), width=width, height=height)
    if svg is None:
        raise HTTPException(status_code=400, detail="Invalid SMILES")
    return Response(content=svg, media_type="image/svg+xml")


@app.get("/molecule/png", tags=["Molecules"])
async def molecule_png(
    smiles: str = Query(..., description="SMILES string"),
    width:  int = Query(400, ge=100, le=800),
    height: int = Query(300, ge=100, le=800),
):
    """Return 2D PNG structure image."""
    png = predictor.get_png(smiles.strip(), width=width, height=height)
    if png is None:
        raise HTTPException(status_code=400, detail="Invalid SMILES")
    return Response(content=png, media_type="image/png")


@app.get("/molecule/3d", tags=["Molecules"])
async def molecule_3d(
    smiles: str = Query(..., description="SMILES string"),
):
    """Return 3D coordinates in SDF format."""
    sdf = predictor.get_3d_sdf(smiles.strip())
    if sdf is None:
        raise HTTPException(status_code=400, detail="Invalid SMILES or 3D embedding failed")
    return Response(content=sdf, media_type="chemical/x-mdl-sdfile")


@app.get("/molecule/standardize", tags=["Molecules"])
async def molecule_standardize(
    smiles: str = Query(..., description="SMILES string"),
):
    """Return canonical SMILES, InChI, InChIKey, molecular formula."""
    try:
        return predictor.standardize(smiles.strip())
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/molecule/similarity", tags=["Molecules"])
async def molecule_similarity(
    smiles1: str = Query(..., description="First SMILES"),
    smiles2: str = Query(..., description="Second SMILES"),
):
    """Tanimoto similarity (ECFP4) between two molecules."""
    try:
        return predictor.tanimoto_similarity(smiles1.strip(), smiles2.strip())
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/molecule/compare", tags=["Molecules"])
async def molecule_compare(request: CompareRequest):
    """Full side-by-side comparison of two molecules."""
    try:
        return predictor.compare(request.smiles1.strip(), request.smiles2.strip())
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception("Compare failed")
        raise HTTPException(status_code=500, detail="Comparison error")


@app.get("/molecule/alerts", tags=["Molecules"])
async def molecule_alerts(
    smiles: str = Query(..., description="SMILES string"),
):
    """Check PAINS and Brenk structural alerts."""
    try:
        from rdkit import Chem
        mol = Chem.MolFromSmiles(smiles.strip())
        if mol is None:
            raise HTTPException(status_code=400, detail="Invalid SMILES")
        return predictor._get_alerts(mol)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/molecule/variants", tags=["Molecules"])
async def molecule_variants(
    smiles: str = Query(..., description="SMILES string"),
    n: int = Query(6, ge=1, le=12, description="Number of variants"),
):
    """Generate simple structural analogs."""
    try:
        variants = predictor.get_variants(smiles.strip(), n_variants=n)
        return {"base_smiles": smiles, "variants": variants}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# ── External DB proxy ───────────────────────────────────────────────────

@app.get("/pubchem/search", tags=["External"])
async def pubchem_search(
    name: str = Query(..., description="Compound name (e.g. aspirin)"),
):
    """Search PubChem by compound name → SMILES and basic properties."""
    try:
        url = (
            f"https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/{name}"
            "/property/IsomericSMILES,CanonicalSMILES,MolecularFormula,MolecularWeight,IUPACName/JSON"
        )
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url)
        if resp.status_code == 404:
            raise HTTPException(status_code=404, detail=f"'{name}' not found in PubChem")
        resp.raise_for_status()
        data = resp.json()
        props = data["PropertyTable"]["Properties"]
        return {
            "query": name,
            "results": [
                {
                    "cid":     p.get("CID"),
                    "smiles":  p.get("IsomericSMILES") or p.get("CanonicalSMILES") or p.get("SMILES"),
                    "formula": p.get("MolecularFormula"),
                    "mw":      p.get("MolecularWeight"),
                    "iupac":   p.get("IUPACName"),
                }
                for p in props[:5]
            ],
        }
    except HTTPException:
        raise
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="PubChem API timeout")
    except Exception as e:
        logger.exception("PubChem search failed")
        raise HTTPException(status_code=500, detail=str(e))
