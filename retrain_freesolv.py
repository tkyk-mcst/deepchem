"""
FreeSolv 再学習 — Navin 実験値 (expt) を使用。
DeepChem 内部の calc 値ではなく、実測値で学習する。
学習と検証は分離して報告する。
"""
import os, sys, pickle, logging
from pathlib import Path
import numpy as np
import pandas as pd

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

_BASE      = Path(__file__).parent
MODEL_DIR  = str(_BASE / "deepchem-api" / "saved_models" / "freesolv")
DATA_BASE  = str(_BASE / "MS_prediction dataset" / "FreeSolv")
FP_SIZE    = 2048
FP_RADIUS  = 4


def main():
    import deepchem as dc

    # ── 1. データロード ──────────────────────────────────────────────────────
    logger.info("Loading Navin FreeSolv (expt column) ...")
    df_in  = pd.read_csv(os.path.join(DATA_BASE, "FreeSolv_input.csv"))
    df_out = pd.read_csv(os.path.join(DATA_BASE, "FreeSolv_output.csv"))

    smiles = df_in["smiles"].tolist()
    y_vals = df_out["expt"].values.reshape(-1, 1).astype(np.float32)

    logger.info(f"  Total molecules: {len(smiles)}")
    logger.info(f"  y range: {y_vals.min():.3f} to {y_vals.max():.3f}  "
                f"mean={y_vals.mean():.3f}  std={y_vals.std():.3f}")

    # ── 2. DeepChem Dataset 作成 ─────────────────────────────────────────────
    logger.info("Featurizing with ECFP4 ...")
    feat = dc.feat.CircularFingerprint(size=FP_SIZE, radius=FP_RADIUS)
    X = feat.featurize(smiles)

    # 無効 SMILES を除外
    valid_mask = np.array([x is not None and x.shape == (FP_SIZE,) for x in X])
    X_valid    = np.stack([x for x, ok in zip(X, valid_mask) if ok])
    y_valid    = y_vals[valid_mask]
    ids_valid  = [s for s, ok in zip(smiles, valid_mask) if ok]
    logger.info(f"  Valid molecules: {valid_mask.sum()} / {len(smiles)}")

    dataset = dc.data.NumpyDataset(X=X_valid, y=y_valid, ids=ids_valid)

    # ── 3. Train / Valid / Test 分割 (scaffold, 80:10:10) ───────────────────
    logger.info("Splitting (scaffold 80:10:10) ...")
    splitter = dc.splits.ScaffoldSplitter()
    train_ds, valid_ds, test_ds = splitter.train_valid_test_split(
        dataset, frac_train=0.8, frac_valid=0.1, frac_test=0.1
    )
    logger.info(f"  train={len(train_ds)}  valid={len(valid_ds)}  test={len(test_ds)}")

    # ── 4. 正規化 ────────────────────────────────────────────────────────────
    logger.info("Applying NormalizationTransformer ...")
    transformer = dc.trans.NormalizationTransformer(
        transform_y=True, dataset=train_ds
    )
    train_ds = transformer.transform(train_ds)
    valid_ds = transformer.transform(valid_ds)
    test_ds  = transformer.transform(test_ds)

    # transformer のパラメーター確認
    y0 = transformer.untransform(np.array([[0.0]]))
    y1 = transformer.untransform(np.array([[1.0]]))
    logger.info(f"  untransform(0) = {y0[0][0]:.4f}  (= original mean)")
    logger.info(f"  untransform(1) = {y1[0][0]:.4f}  (= mean + std)")
    logger.info(f"  original mean  ≈ {y0[0][0]:.4f}  std ≈ {y1[0][0]-y0[0][0]:.4f}")

    # ── 5. 学習 ──────────────────────────────────────────────────────────────
    os.makedirs(MODEL_DIR, exist_ok=True)
    model = dc.models.MultitaskRegressor(
        n_tasks=1,
        n_features=FP_SIZE,
        layer_sizes=[1024, 512, 128],
        dropouts=0.15,
        model_dir=MODEL_DIR,
        batch_size=32,
        learning_rate=0.0005,
    )

    logger.info("Training (120 epochs) ...")
    metric_r2   = dc.metrics.Metric(dc.metrics.pearson_r2_score)
    metric_mae  = dc.metrics.Metric(dc.metrics.mean_absolute_error)

    best_valid_r2 = -999
    for epoch_block in range(4):  # 4 x 30 epochs
        model.fit(train_ds, nb_epoch=30)
        train_score = model.evaluate(train_ds, [metric_r2, metric_mae], [transformer])
        valid_score = model.evaluate(valid_ds, [metric_r2, metric_mae], [transformer])
        ep = (epoch_block + 1) * 30
        logger.info(
            f"  [Epoch {ep:3d}]  "
            f"train R²={train_score['pearson_r2_score']:.4f}  MAE={train_score['mean_absolute_error']:.3f}  |  "
            f"valid R²={valid_score['pearson_r2_score']:.4f}  MAE={valid_score['mean_absolute_error']:.3f}"
        )
        if valid_score["pearson_r2_score"] > best_valid_r2:
            best_valid_r2 = valid_score["pearson_r2_score"]
            model.save_checkpoint()
            logger.info(f"    -> Best valid R² so far: {best_valid_r2:.4f}  (checkpoint saved)")

    # ── 6. テスト評価 ────────────────────────────────────────────────────────
    logger.info("\n=== Final Test Evaluation ===")
    test_score = model.evaluate(test_ds, [metric_r2, metric_mae], [transformer])
    logger.info(f"  Test R²  : {test_score['pearson_r2_score']:.4f}")
    logger.info(f"  Test MAE : {test_score['mean_absolute_error']:.3f} kcal/mol")

    # 実際の予測 vs 真値を5件表示
    preds = model.predict(test_ds)
    preds_orig = transformer.untransform(preds)
    true_orig  = transformer.untransform(test_ds.y)
    logger.info("\n  Sample predictions (kcal/mol):")
    for i in range(min(5, len(preds_orig))):
        logger.info(f"    true={true_orig[i][0]:7.3f}  pred={preds_orig[i][0]:7.3f}  "
                    f"err={abs(true_orig[i][0]-preds_orig[i][0]):.3f}")

    # ── 7. 保存 ──────────────────────────────────────────────────────────────
    transformers = [transformer]
    with open(os.path.join(MODEL_DIR, "transformers.pkl"), "wb") as f:
        pickle.dump(transformers, f)
    with open(os.path.join(MODEL_DIR, "tasks.pkl"), "wb") as f:
        pickle.dump(["expt"], f)

    logger.info(f"\nModel saved to {MODEL_DIR}")
    logger.info("Done.")


if __name__ == "__main__":
    main()
