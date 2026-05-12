"""
DeepChem predictor — comprehensive version.
Models: Solubility / BBBP / Tox21 / ClinTox / HIV
Extras: QED score, MC Dropout uncertainty, PAINS/Brenk alerts,
        3D coordinates, PNG image, Tanimoto similarity
Compatible with DeepChem 2.8+ (no DGL required).
"""

import glob
import io
import os
import pickle
import logging
from typing import Optional

import numpy as np
import deepchem as dc
from rdkit import Chem
from rdkit.Chem import (
    Descriptors, rdMolDescriptors, QED, AllChem,
    Draw, rdDepictor
)
from rdkit.Chem.Draw import rdMolDraw2D
from rdkit.Chem import FilterCatalog

logger = logging.getLogger(__name__)

_default_model_dir = "/app/saved_models"
_local_model_dir   = os.path.join(os.path.dirname(__file__), "saved_models")
if not os.environ.get("MODEL_DIR") and os.path.isdir(_local_model_dir):
    _default_model_dir = _local_model_dir
MODEL_DIR = os.environ.get("MODEL_DIR", _default_model_dir)
FP_SIZE    = 2048
FP_RADIUS  = 4
N_DROPOUT_SAMPLES = 20


def _has_checkpoint(model_dir: str) -> bool:
    return bool(glob.glob(os.path.join(model_dir, "*.pt")))


def _load_tasks(model_dir: str):
    path = os.path.join(model_dir, "tasks.pkl")
    if os.path.exists(path):
        with open(path, "rb") as f:
            return pickle.load(f)
    return None


# ── Model loader helpers ──────────────────────────────────────────────────

def _load_regressor(model_dir, n_tasks=1):
    m = dc.models.MultitaskRegressor(
        n_tasks=n_tasks, n_features=FP_SIZE,
        layer_sizes=[1024, 512, 128], dropouts=0.25,
        model_dir=model_dir,
    )
    m.restore()
    return m


def _load_classifier(model_dir, n_tasks):
    m = dc.models.MultitaskClassifier(
        n_tasks=n_tasks, n_features=FP_SIZE,
        layer_sizes=[1024, 512, 128], dropouts=0.25,
        model_dir=model_dir,
    )
    m.restore()
    return m


# ── PAINS catalog (initialized once) ─────────────────────────────────────
_PAINS_CATALOG = None
_BRENK_CATALOG = None

def _get_pains_catalog():
    global _PAINS_CATALOG
    if _PAINS_CATALOG is None:
        params = FilterCatalog.FilterCatalogParams()
        params.AddCatalog(FilterCatalog.FilterCatalogParams.FilterCatalogs.PAINS)
        _PAINS_CATALOG = FilterCatalog.FilterCatalog(params)
    return _PAINS_CATALOG

def _get_brenk_catalog():
    global _BRENK_CATALOG
    if _BRENK_CATALOG is None:
        params = FilterCatalog.FilterCatalogParams()
        params.AddCatalog(FilterCatalog.FilterCatalogParams.FilterCatalogs.BRENK)
        _BRENK_CATALOG = FilterCatalog.FilterCatalog(params)
    return _BRENK_CATALOG


# ── Main predictor class ──────────────────────────────────────────────────

class MoleculePredictor:
    def __init__(self):
        self._featurizer = dc.feat.CircularFingerprint(size=FP_SIZE, radius=FP_RADIUS)
        self.models: dict = {}
        self.tasks:  dict = {}
        self._transformers: dict = {}
        self.sol_transformers = None  # kept for backward compat

    def initialize(self):
        specs = [
            ("solubility", 1,  "regressor"),
            ("freesolv",   1,  "regressor"),
            ("lipo",       1,  "regressor"),
            ("bbbp",       1,  "classifier"),
            ("bace",       1,  "classifier"),
            ("tox21",      12, "classifier"),
            ("clintox",    2,  "classifier"),
            ("hiv",        1,  "classifier"),
            ("sider",      27, "classifier"),
            ("muv",        17, "classifier"),
        ]
        for name, default_n, kind in specs:
            mdir = os.path.join(MODEL_DIR, name)
            if not _has_checkpoint(mdir):
                logger.warning(f"[{name}] checkpoint not found — skipping.")
                continue
            try:
                task_list = _load_tasks(mdir)
                n = len(task_list) if task_list else default_n
                if kind == "regressor":
                    self.models[name] = _load_regressor(mdir, n)
                else:
                    self.models[name] = _load_classifier(mdir, n)
                self.tasks[name] = task_list or [name]
                logger.info(f"[{name}] loaded ({n} tasks).")
            except Exception as e:
                logger.error(f"[{name}] load failed: {e}")

        for reg_name in ("solubility", "freesolv", "lipo"):
            tp = os.path.join(MODEL_DIR, reg_name, "transformers.pkl")
            if os.path.exists(tp):
                with open(tp, "rb") as f:
                    self._transformers[reg_name] = pickle.load(f)
        # backward-compat alias
        self.sol_transformers = self._transformers.get("solubility")

        # warm up PAINS catalog
        try:
            _get_pains_catalog()
            _get_brenk_catalog()
            logger.info("PAINS/Brenk catalogs loaded.")
        except Exception as e:
            logger.warning(f"Alert catalogs failed: {e}")

    # ── Public API ──────────────────────────────────────────────────────

    def predict(self, smiles: str) -> dict:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            raise ValueError(f"Invalid SMILES: {smiles!r}")

        dataset = self._make_dataset(smiles)
        canonical = Chem.MolToSmiles(mol)

        return {
            "smiles":        smiles,
            "canonical_smiles": canonical,
            "valid":         True,
            "descriptors":   self._rdkit_descriptors(mol),
            "drug_likeness": self._drug_likeness(mol),
            "alerts":        self._get_alerts(mol),
            "predictions":   self._run_all_predictions(smiles, dataset),
            "models_loaded": list(self.models.keys()),
        }

    def predict_batch(self, smiles_list: list) -> list:
        results = []
        for smi in smiles_list:
            try:
                results.append(self.predict(smi.strip()))
            except Exception as e:
                results.append({
                    "smiles": smi,
                    "valid": False,
                    "error": str(e),
                })
        return results

    def get_svg(self, smiles: str, width=300, height=200,
                highlight_atoms: list = None) -> Optional[str]:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            return None
        rdDepictor.Compute2DCoords(mol)
        drawer = rdMolDraw2D.MolDraw2DSVG(width, height)
        drawer.drawOptions().addStereoAnnotation = True
        if highlight_atoms:
            drawer.DrawMolecule(mol, highlightAtoms=highlight_atoms)
        else:
            drawer.DrawMolecule(mol)
        drawer.FinishDrawing()
        return drawer.GetDrawingText()

    def get_png(self, smiles: str, width=400, height=300) -> Optional[bytes]:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            return None
        rdDepictor.Compute2DCoords(mol)
        drawer = rdMolDraw2D.MolDraw2DCairo(width, height)
        drawer.DrawMolecule(mol)
        drawer.FinishDrawing()
        return drawer.GetDrawingText()

    def get_3d_sdf(self, smiles: str) -> Optional[str]:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            return None
        mol = Chem.AddHs(mol)
        result = AllChem.EmbedMolecule(mol, AllChem.ETKDGv3())
        if result != 0:
            # fallback
            AllChem.EmbedMolecule(mol, AllChem.ETKDG())
        try:
            AllChem.MMFFOptimizeMolecule(mol)
        except Exception:
            pass
        from rdkit.Chem import SDWriter
        buf = io.StringIO()
        writer = SDWriter(buf)
        writer.write(mol)
        writer.close()
        return buf.getvalue()

    def standardize(self, smiles: str) -> dict:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            raise ValueError(f"Invalid SMILES: {smiles!r}")
        canonical = Chem.MolToSmiles(mol)
        inchi = Chem.MolToInchi(mol) if hasattr(Chem, 'MolToInchi') else None
        inchikey = Chem.InchiToInchiKey(inchi) if inchi and hasattr(Chem, 'InchiToInchiKey') else None

        # Try rdkit inchi
        try:
            from rdkit.Chem.inchi import MolToInchi, InchiToInchiKey
            inchi = MolToInchi(mol)
            inchikey = InchiToInchiKey(inchi) if inchi else None
        except Exception:
            pass

        formula = rdMolDescriptors.CalcMolFormula(mol)
        return {
            "input_smiles": smiles,
            "canonical_smiles": canonical,
            "molecular_formula": formula,
            "inchi": inchi,
            "inchikey": inchikey,
        }

    def tanimoto_similarity(self, smiles1: str, smiles2: str) -> dict:
        mol1 = Chem.MolFromSmiles(smiles1)
        mol2 = Chem.MolFromSmiles(smiles2)
        if mol1 is None:
            raise ValueError(f"Invalid SMILES: {smiles1!r}")
        if mol2 is None:
            raise ValueError(f"Invalid SMILES: {smiles2!r}")
        from rdkit import DataStructs
        fp1 = AllChem.GetMorganFingerprintAsBitVect(mol1, 2, nBits=2048)
        fp2 = AllChem.GetMorganFingerprintAsBitVect(mol2, 2, nBits=2048)
        sim = DataStructs.TanimotoSimilarity(fp1, fp2)
        return {
            "smiles1": smiles1,
            "smiles2": smiles2,
            "tanimoto_similarity": round(float(sim), 4),
            "interpretation": _sim_label(sim),
        }

    def compare(self, smiles1: str, smiles2: str) -> dict:
        p1 = self.predict(smiles1)
        p2 = self.predict(smiles2)
        sim = self.tanimoto_similarity(smiles1, smiles2)
        return {
            "molecule_1": p1,
            "molecule_2": p2,
            "similarity": sim,
        }

    def compute_for_ga(self, selfies_str: str) -> dict:
        """Flat property dict for GA score function. Uses real DeepChem predictions."""
        try:
            import selfies as sf
            smiles = sf.decoder(selfies_str)
            mol = Chem.MolFromSmiles(smiles)
            if mol is None:
                return {"valid": False}
            result = self.predict(smiles)
            d     = result.get("descriptors", {})
            dl    = result.get("drug_likeness", {})
            preds = result.get("predictions", {})
            bbbp  = preds.get("bbbp", {})
            sol   = preds.get("solubility", {})
            try:
                from rdkit.Contrib.SA_Score import sascorer
                sa = round(sascorer.calculateScore(mol), 3)
            except ImportError:
                sa = None
            return {
                "valid":    True,
                "qed":      dl.get("qed"),
                "sa_score": sa,
                "logP":     d.get("logp"),
                "tpsa":     d.get("tpsa"),
                "mw":       d.get("molecular_weight"),
                "hbd":      d.get("hbd"),
                "hba":      d.get("hba"),
                "bbbp":     bbbp.get("probability"),
                "logS":     sol.get("logS"),
            }
        except Exception:
            return {"valid": False}

    def props_for_result(self, smiles: str) -> dict:
        """Flat property dict to enrich GA result entries."""
        try:
            mol = Chem.MolFromSmiles(smiles)
            if mol is None:
                return {}
            result = self.predict(smiles)
            d     = result.get("descriptors", {})
            dl    = result.get("drug_likeness", {})
            preds = result.get("predictions", {})
            bbbp  = preds.get("bbbp", {})
            sol   = preds.get("solubility", {})
            try:
                from rdkit.Contrib.SA_Score import sascorer
                sa = round(sascorer.calculateScore(mol), 3)
            except ImportError:
                sa = None
            return {
                "qed":      dl.get("qed"),
                "sa_score": sa,
                "logP":     d.get("logp"),
                "tpsa":     d.get("tpsa"),
                "mw":       d.get("molecular_weight"),
                "hbd":      d.get("hbd"),
                "hba":      d.get("hba"),
                "bbbp":     bbbp.get("probability"),
                "logS":     sol.get("logS"),
            }
        except Exception:
            return {}

    def get_variants(self, smiles: str, n_variants: int = 6) -> list:
        """Generate simple analogs by swapping common fragments."""
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            raise ValueError(f"Invalid SMILES: {smiles!r}")

        from rdkit.Chem import RWMol
        variants = []
        # substituent swaps: H → F, H → CH3, H → OH, H → NH2, H → Cl, H → CN
        substitutions = [
            ("[H]", "F",    "F-substituted"),
            ("[H]", "OC",   "methoxy"),
            ("[H]", "N",    "amino"),
            ("[H]", "Cl",   "chloro"),
            ("[H]", "C#N",  "cyano"),
            ("[H]", "C",    "methyl"),
        ]
        base = Chem.MolToSmiles(mol)
        for from_smi, to_smi, label in substitutions:
            try:
                rxn_smarts = f"[c:1][H]>>[c:1]{to_smi}"
                from rdkit.Chem import AllChem as AC
                rxn = AC.ReactionFromSmarts(rxn_smarts)
                prods = rxn.RunReactants((mol,))
                if prods:
                    prod_mol = prods[0][0]
                    Chem.SanitizeMol(prod_mol)
                    prod_smi = Chem.MolToSmiles(prod_mol)
                    if prod_smi != base and prod_smi not in [v["smiles"] for v in variants]:
                        variants.append({"smiles": prod_smi, "modification": label})
                        if len(variants) >= n_variants:
                            break
            except Exception:
                continue
        return variants[:n_variants]

    # ── Predictions ─────────────────────────────────────────────────────

    def _run_all_predictions(self, smiles, dataset) -> dict:
        result = {}
        # ── Regression ──────────────────────────────────────────────────
        if "solubility" in self.models:
            result["solubility"] = self._predict_regression(
                "solubility", dataset,
                value_key="logS", unit="log(mol/L)", label_fn=_solubility_label,
            )
        if "freesolv" in self.models:
            result["freesolv"] = self._predict_regression(
                "freesolv", dataset,
                value_key="dG", unit="kcal/mol", label_fn=_freesolv_label,
            )
        if "lipo" in self.models:
            result["lipo"] = self._predict_regression(
                "lipo", dataset,
                value_key="logD", unit="", label_fn=_lipo_label,
            )
        # ── Binary classification ────────────────────────────────────────
        if "bbbp" in self.models:
            result["bbbp"] = self._predict_binary(
                "bbbp", dataset, label_true="Permeable", label_false="Not Permeable"
            )
        if "bace" in self.models:
            result["bace"] = self._predict_binary(
                "bace", dataset, label_true="Inhibitor", label_false="Non-Inhibitor"
            )
        if "hiv" in self.models:
            result["hiv"] = self._predict_binary(
                "hiv", dataset, label_true="Active", label_false="Inactive"
            )
        # ── Multitask classification ─────────────────────────────────────
        if "tox21" in self.models:
            result["tox21"] = self._predict_multitask("tox21", dataset)
        if "clintox" in self.models:
            result["clintox"] = self._predict_multitask("clintox", dataset)
        if "sider" in self.models:
            result["sider"] = self._predict_multitask("sider", dataset)
        if "muv" in self.models:
            result["muv"] = self._predict_multitask("muv", dataset)
        return result

    def _predict_regression(self, name: str, dataset,
                             value_key: str, unit: str, label_fn) -> dict:
        try:
            model = self.models[name]
            pred = model.predict(dataset)
            transformers = self._transformers.get(name)
            if transformers:
                for t in reversed(transformers):
                    pred = t.untransform(pred)
            val = float(pred[0][0])
            uncertainty = self._dropout_uncertainty_regression(model, dataset)
            return {
                value_key:     round(val, 3),
                "unit":        unit,
                "label":       label_fn(val),
                "uncertainty": uncertainty,
            }
        except Exception as e:
            logger.warning(f"{name} prediction error: {e}")
            return {}

    def _predict_binary(self, name, dataset, label_true, label_false) -> dict:
        try:
            model = self.models[name]
            pred = model.predict(dataset)
            prob = float(_extract_prob(pred))
            uncertainty = self._dropout_uncertainty_classifier(model, dataset)
            return {
                "probability": round(prob, 3),
                "label":       label_true if prob >= 0.5 else label_false,
                "uncertainty": uncertainty,
            }
        except Exception as e:
            logger.warning(f"{name} prediction error: {e}")
            return {}

    def _predict_multitask(self, name, dataset) -> dict:
        try:
            model = self.models[name]
            tasks = self.tasks[name]
            n     = len(tasks)
            local_ds = dc.data.NumpyDataset(
                X=dataset.X, y=np.zeros((1, n)), ids=dataset.ids
            )
            pred = model.predict(local_ds)
            result = {}
            for i, task in enumerate(tasks):
                prob = float(_extract_prob(pred, task_idx=i))
                if name == "tox21":
                    label = "Toxic" if prob >= 0.5 else "Non-toxic"
                else:
                    label = "Positive" if prob >= 0.5 else "Negative"
                result[task] = {"probability": round(prob, 3), "label": label}
            return result
        except Exception as e:
            logger.warning(f"{name} prediction error: {e}")
            return {}

    # ── MC Dropout uncertainty ────────────────────────────────────────

    def _dropout_uncertainty_regression(self, model, dataset) -> Optional[dict]:
        try:
            mean, var = model.predict_uncertainty(dataset)
            std = float(np.sqrt(var[0][0]))
            return {"std": round(std, 3)}
        except Exception:
            return None

    def _dropout_uncertainty_classifier(self, model, dataset) -> Optional[dict]:
        try:
            mean, var = model.predict_uncertainty(dataset)
            v = float(np.mean(var))
            return {"variance": round(v, 4)}
        except Exception:
            return None

    # ── Alerts (PAINS / Brenk) ───────────────────────────────────────

    def _get_alerts(self, mol) -> dict:
        pains = []
        brenk = []
        try:
            catalog = _get_pains_catalog()
            matches = catalog.GetMatches(mol)
            for m in matches:
                pains.append(m.GetDescription())
        except Exception as e:
            logger.debug(f"PAINS check failed: {e}")
        try:
            catalog = _get_brenk_catalog()
            matches = catalog.GetMatches(mol)
            for m in matches:
                brenk.append(m.GetDescription())
        except Exception as e:
            logger.debug(f"Brenk check failed: {e}")
        return {
            "pains": pains,
            "brenk": brenk,
            "has_alerts": len(pains) > 0 or len(brenk) > 0,
        }

    # ── RDKit ─────────────────────────────────────────────────────────

    def _make_dataset(self, smiles):
        features = self._featurizer.featurize([smiles])
        return dc.data.NumpyDataset(
            X=features, y=np.zeros((1, 1)), ids=np.array([smiles])
        )

    def _rdkit_descriptors(self, mol) -> dict:
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
            "stereo_centers":   int(len(Chem.FindMolChiralCenters(mol, includeUnassigned=True))),
            "molecular_formula": rdMolDescriptors.CalcMolFormula(mol),
            "fsp3":             round(float(rdMolDescriptors.CalcFractionCSP3(mol)), 3),
        }

    def _drug_likeness(self, mol) -> dict:
        desc = self._rdkit_descriptors(mol)
        checks = {
            "mw_ok":   desc["molecular_weight"] <= 500,
            "logp_ok": desc["logp"] <= 5,
            "hbd_ok":  desc["hbd"] <= 5,
            "hba_ok":  desc["hba"] <= 10,
        }
        violations = sum(1 for v in checks.values() if not v)

        # Veber rules
        veber_ok = desc["rotatable_bonds"] <= 10 and desc["tpsa"] <= 140

        try:
            qed = round(float(QED.qed(mol)), 3)
        except Exception:
            qed = None

        return {
            **checks,
            "violations":  violations,
            "drug_like":   violations <= 1,
            "veber_ok":    veber_ok,
            "qed":         qed,
        }


# ── Utilities ─────────────────────────────────────────────────────────────

def _extract_prob(pred, task_idx=0):
    p = pred[0][task_idx]
    if hasattr(p, "__len__") and len(p) == 2:
        return float(p[1])
    return float(p)


def _solubility_label(log_s: float) -> str:
    if log_s > -1:  return "Highly Soluble"
    if log_s > -3:  return "Soluble"
    if log_s > -5:  return "Moderately Soluble"
    return "Poorly Soluble"


def _freesolv_label(dg: float) -> str:
    if dg < -10: return "Very Favorable Hydration"
    if dg < -5:  return "Favorable Hydration"
    if dg < 0:   return "Moderate Hydration"
    return "Unfavorable Hydration"


def _lipo_label(log_d: float) -> str:
    if log_d < 0:  return "Hydrophilic"
    if log_d < 2:  return "Moderate"
    if log_d < 4:  return "Lipophilic"
    return "Highly Lipophilic"


def _sim_label(sim: float) -> str:
    if sim >= 0.85: return "Very Similar"
    if sim >= 0.65: return "Similar"
    if sim >= 0.40: return "Somewhat Similar"
    return "Dissimilar"
