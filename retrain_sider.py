"""
SIDER 再学習スクリプト。
改善点:
  - splitter: scaffold -> random (SIDERはscaffold splitで過度に困難)
  - nb_epoch: 40 -> 100
  - dropouts: 0.25 -> 0.1
  - learning_rate: 0.001 -> 0.0005
学習後: saved_models/sider/ を上書きして API に反映。
"""
import os, sys, pickle, logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

MODEL_DIR = r"C:\Users\takay\python379\DeepChem\deepchem-api\saved_models"
FP_SIZE   = 2048
FP_RADIUS = 4


def main():
    import deepchem as dc

    out = os.path.join(MODEL_DIR, "sider")
    os.makedirs(out, exist_ok=True)

    logger.info("Loading SIDER (27 endpoints) with random splitter ...")
    tasks, datasets, transformers = dc.molnet.load_sider(
        featurizer=dc.feat.CircularFingerprint(size=FP_SIZE, radius=FP_RADIUS),
        splitter="random",
    )
    train, valid, test = datasets
    logger.info(f"  train={len(train)}, valid={len(valid)}, test={len(test)}, tasks={len(tasks)}")

    model = dc.models.MultitaskClassifier(
        n_tasks=len(tasks),
        n_features=FP_SIZE,
        layer_sizes=[1024, 512, 128],
        dropouts=0.1,
        model_dir=out,
        batch_size=64,
        learning_rate=0.0005,
    )

    logger.info("Training (100 epochs) ...")
    loss = model.fit(train, nb_epoch=100, checkpoint_interval=25)
    model.save_checkpoint()
    logger.info(f"  Final loss: {loss}")

    score = model.evaluate(
        test,
        [dc.metrics.Metric(dc.metrics.roc_auc_score)],
        transformers,
    )
    logger.info(f"  Test AUC: {score}")

    with open(os.path.join(out, "tasks.pkl"), "wb") as f:
        pickle.dump(tasks, f)
    logger.info(f"  Model saved to {out}")
    logger.info("Done.")


if __name__ == "__main__":
    main()
