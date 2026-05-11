"""
Model training script — runs at Docker build time.
Each model is trained in a separate subprocess to avoid DGL conflicts.

Models trained:
  1. solubility  — Delaney,  MultitaskRegressor,   1 task  (regression)
  2. bbbp        — BBBP,     MultitaskClassifier,   1 task  (classification)
  3. tox21       — Tox21,    MultitaskClassifier,  12 tasks (classification)
  4. clintox     — ClinTox,  MultitaskClassifier,   2 tasks (classification)
  5. hiv         — HIV,      MultitaskClassifier,   1 task  (classification)
"""

import os
import sys
import pickle
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

MODEL_DIR = os.environ.get("MODEL_DIR", "/app/saved_models")
FP_SIZE = 2048
FP_RADIUS = 4


def _featurizer():
    import deepchem as dc
    return dc.feat.CircularFingerprint(size=FP_SIZE, radius=FP_RADIUS)


def _regressor(n_tasks, model_dir):
    import deepchem as dc
    return dc.models.MultitaskRegressor(
        n_tasks=n_tasks,
        n_features=FP_SIZE,
        layer_sizes=[1024, 512, 128],
        dropouts=0.25,
        model_dir=model_dir,
        batch_size=64,
        learning_rate=0.001,
    )


def _classifier(n_tasks, model_dir):
    import deepchem as dc
    return dc.models.MultitaskClassifier(
        n_tasks=n_tasks,
        n_features=FP_SIZE,
        layer_sizes=[1024, 512, 128],
        dropouts=0.25,
        model_dir=model_dir,
        batch_size=64,
        learning_rate=0.001,
    )


# ── Individual training functions ─────────────────────────────────────────

def train_solubility():
    import pickle, deepchem as dc
    out = os.path.join(MODEL_DIR, "solubility")
    os.makedirs(out, exist_ok=True)

    logger.info("Loading Delaney (solubility)...")
    tasks, datasets, transformers = dc.molnet.load_delaney(
        featurizer=_featurizer(), splitter="scaffold"
    )
    train, valid, test = datasets
    logger.info(f"  {len(train)} train / {len(test)} test")

    model = _regressor(1, out)
    model.fit(train, nb_epoch=60, checkpoint_interval=60)
    model.save_checkpoint()

    score = model.evaluate(test, [dc.metrics.Metric(dc.metrics.pearson_r2_score)], transformers)
    logger.info(f"  Solubility R2: {score}")

    with open(os.path.join(out, "transformers.pkl"), "wb") as f:
        pickle.dump(transformers, f)
    with open(os.path.join(out, "tasks.pkl"), "wb") as f:
        pickle.dump(tasks, f)
    logger.info(f"  Saved to {out}")


def train_bbbp():
    import deepchem as dc
    out = os.path.join(MODEL_DIR, "bbbp")
    os.makedirs(out, exist_ok=True)

    logger.info("Loading BBBP...")
    tasks, datasets, transformers = dc.molnet.load_bbbp(
        featurizer=_featurizer(), splitter="scaffold"
    )
    train, valid, test = datasets
    logger.info(f"  {len(train)} train / {len(test)} test")

    model = _classifier(1, out)
    model.fit(train, nb_epoch=40, checkpoint_interval=40)
    model.save_checkpoint()

    score = model.evaluate(test, [dc.metrics.Metric(dc.metrics.roc_auc_score)], transformers)
    logger.info(f"  BBBP AUC: {score}")

    import pickle
    with open(os.path.join(out, "tasks.pkl"), "wb") as f:
        pickle.dump(tasks, f)
    logger.info(f"  Saved to {out}")


def train_tox21():
    import deepchem as dc
    out = os.path.join(MODEL_DIR, "tox21")
    os.makedirs(out, exist_ok=True)

    logger.info("Loading Tox21 (12 endpoints)...")
    tasks, datasets, transformers = dc.molnet.load_tox21(
        featurizer=_featurizer(), splitter="scaffold"
    )
    train, valid, test = datasets
    logger.info(f"  {len(train)} train / {len(test)} test, tasks: {tasks}")

    model = _classifier(len(tasks), out)
    model.fit(train, nb_epoch=30, checkpoint_interval=30)
    model.save_checkpoint()

    score = model.evaluate(test, [dc.metrics.Metric(dc.metrics.roc_auc_score)], transformers)
    logger.info(f"  Tox21 AUC: {score}")

    import pickle
    with open(os.path.join(out, "tasks.pkl"), "wb") as f:
        pickle.dump(tasks, f)
    logger.info(f"  Saved to {out}")


def train_clintox():
    import deepchem as dc
    out = os.path.join(MODEL_DIR, "clintox")
    os.makedirs(out, exist_ok=True)

    logger.info("Loading ClinTox (2 endpoints)...")
    tasks, datasets, transformers = dc.molnet.load_clintox(
        featurizer=_featurizer(), splitter="scaffold"
    )
    train, valid, test = datasets
    logger.info(f"  {len(train)} train / {len(test)} test, tasks: {tasks}")

    model = _classifier(len(tasks), out)
    model.fit(train, nb_epoch=40, checkpoint_interval=40)
    model.save_checkpoint()

    score = model.evaluate(test, [dc.metrics.Metric(dc.metrics.roc_auc_score)], transformers)
    logger.info(f"  ClinTox AUC: {score}")

    import pickle
    with open(os.path.join(out, "tasks.pkl"), "wb") as f:
        pickle.dump(tasks, f)
    logger.info(f"  Saved to {out}")


def train_hiv():
    import deepchem as dc
    out = os.path.join(MODEL_DIR, "hiv")
    os.makedirs(out, exist_ok=True)

    logger.info("Loading HIV...")
    tasks, datasets, transformers = dc.molnet.load_hiv(
        featurizer=_featurizer(), splitter="scaffold"
    )
    train, valid, test = datasets
    logger.info(f"  {len(train)} train / {len(test)} test, tasks: {tasks}")

    model = _classifier(len(tasks), out)
    model.fit(train, nb_epoch=20, checkpoint_interval=20)
    model.save_checkpoint()

    score = model.evaluate(test, [dc.metrics.Metric(dc.metrics.roc_auc_score)], transformers)
    logger.info(f"  HIV AUC: {score}")

    import pickle
    with open(os.path.join(out, "tasks.pkl"), "wb") as f:
        pickle.dump(tasks, f)
    logger.info(f"  Saved to {out}")


# ── Entry point ────────────────────────────────────────────────────────────

TASKS = {
    "solubility": train_solubility,
    "bbbp":       train_bbbp,
    "tox21":      train_tox21,
    "clintox":    train_clintox,
    "hiv":        train_hiv,
}

if __name__ == "__main__":
    os.makedirs(MODEL_DIR, exist_ok=True)

    if len(sys.argv) > 1:
        task = sys.argv[1]
        if task not in TASKS:
            logger.error(f"Unknown task: {task}. Choose from: {list(TASKS)}")
            sys.exit(1)
        TASKS[task]()
    else:
        import subprocess
        for task in TASKS:
            logger.info(f"=== Launching [{task}] training in subprocess ===")
            result = subprocess.run(
                [sys.executable, __file__, task],
                env={**os.environ, "MODEL_DIR": MODEL_DIR},
            )
            if result.returncode == 0:
                logger.info(f"  [{task}] done.")
            else:
                logger.error(f"  [{task}] failed (exit {result.returncode}).")
        logger.info("All training complete.")
