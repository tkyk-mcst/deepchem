# MoleculeAI — DeepChem Explorer

## このプロジェクトは何か

**化学式（SMILES）を入力するだけで、分子の薬物動態・毒性・物性を AI が予測する Flutter Web アプリ。**

創薬研究・化学研究向けの ADMET（吸収・分布・代謝・排泄・毒性）予測ツール。

---

## ディレクトリ構成

```
DeepChem/
├── mol_app/                    ← Flutter Web フロントエンド（ソース）
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/app_config.dart   ← API URL設定（localhost:8282）
│   │   ├── models/models.dart       ← データモデル（PredictionResult等）
│   │   ├── services/api_service.dart ← バックエンドAPI呼び出し
│   │   ├── screens/
│   │   │   ├── home_screen.dart     ← ホーム（サンプル分子グリッド）
│   │   │   ├── predict_screen.dart  ← 単一分子予測（メイン機能）
│   │   │   ├── batch_screen.dart    ← バッチ予測（複数分子）
│   │   │   ├── compare_screen.dart  ← 2分子比較
│   │   │   ├── search_screen.dart   ← PubChem検索
│   │   │   └── optimize_screen.dart ← SELFIES GA最適化
│   │   └── widgets/
│   │       ├── admet_radar.dart     ← ADMETレーダーチャート（fl_chart）
│   │       ├── molecule_image.dart  ← SVG分子画像表示
│   │       └── property_cards.dart  ← 物性値カード群
│   ├── build/web/              ← ビルド済みファイル（本番用）
│   └── pubspec.yaml
│
├── deepchem-api/               ← ★バックエンド（DeepChem + RDKit）ポート 8282
│   ├── main.py                 ← FastAPI エンドポイント定義
│   ├── predictor.py            ← DeepChem/RDKit 予測ロジック
│   ├── optimization/           ← SELFIES GA最適化モジュール
│   │   ├── selfies_utils.py
│   │   └── genetic_algorithm.py
│   ├── saved_models/           ← 学習済みDeepChemモデル
│   ├── train_models.py         ← モデル学習スクリプト
│   ├── requirements.txt
│   ├── Dockerfile
│   └── cloudbuild.yaml         ← Cloud Run デプロイ設定
│
├── playwright_tests/
│   ├── test_full.js            ← E2Eテスト全機能（12スクリーンショット生成）
│   ├── measure_layout.js       ← 座標測定用グリッドオーバーレイ
│   └── full/                   ← テスト結果スクリーンショット
│
├── docs/
│   └── index.html              ← 日本語ドキュメント（薄紫テーマ）
│
├── sample_batch.csv            ← バッチ予測用サンプルCSV（10分子）
└── start_servers.bat           ← 両サーバー一括起動バッチ（Windows）
```

---

## 起動方法

### 通常起動（ローカル開発）

```bash
# ① 本番バックエンド（DeepChem、ポート 8282）
cd C:\Users\takay\python379\DeepChem\deepchem-api
C:\Users\takay\AppData\Local\Programs\Python\Python39\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8282

# ② Flutter Web（ポート 3000）
cd C:\Users\takay\python379\DeepChem
C:\Users\takay\AppData\Local\Programs\Python\Python39\python.exe -m http.server 3000 --directory mol_app/build/web

# アクセス
# アプリ:     http://localhost:3000
# Swagger UI: http://localhost:8282/docs
```

### 注意事項
- Flutter ビルド済みJS内の API URL は `localhost:8282` にハードコード済み
- ポート 3000 の http.server は `mol_app/build/web/` を配信する
- ポート 8080 は別プロジェクト（FEM12samples_Hook）が使用中 → 8282 を使うこと
- バックエンドプロセスは bash セッション終了で死ぬため、永続化には `cmd /c start ...` か同一セッションで起動すること

### E2Eテスト実行

```bash
cd C:\Users\takay\python379\DeepChem
# バックエンドを先に起動してから（test_full.js内で自動起動するためそのままでもOK）
node playwright_tests/test_full.js
```

---

## アーキテクチャ

```
ブラウザ（Flutter Web / CanvasKit）
    ↕ HTTP/JSON (localhost:8282)
mock_backend.py（FastAPI + RDKit）
    ↕ HTTPS
pubchem.ncbi.nlm.nih.gov（Search機能のみ）
```

---

## 主要機能

| 機能 | 画面 | API エンドポイント |
|------|------|-------------------|
| 単一分子予測（ADMET全項目） | Predict | POST /predict |
| バッチ予測（最大100分子） | Batch | POST /predict/batch |
| 2分子比較（Tanimoto類似度） | Compare | POST /molecule/compare |
| PubChem名前検索→SMILES取得 | Search | GET /pubchem/search |
| 分子構造画像（SVG） | 全画面 | GET /molecule/image |
| 構造アナログ生成 | Predict | GET /molecule/variants |
| PAINS/Brenkアラート | Predict | GET /molecule/alerts |

---

## 予測モデルの概要

### mock_backend.py（ローカル用）
- **RDKit で実計算**: 分子量・LogP・TPSA・HBD/HBA・回転可能結合数・Fsp3・分子式・PAINS/Brenk
- **数式ベースのモックML**: 
  - logS = Yalkowsky方程式近似 (-0.01*MW + 0.5*logP...)
  - BBBP = sigmoid(logP/MW/TPSA から算出)
  - Tox21/ClinTox/HIV = ベータ分布ベースの擬似予測

### deepchem-api/（本番用 / GPU推奨）
- Delaney データセット（1,128分子）→ 水溶性(logS)
- BBBP データセット（2,050分子）→ 血液脳関門透過性
- Tox21 データセット（8,014分子）→ 12種毒性エンドポイント
- ClinTox データセット（1,491分子）→ 臨床毒性
- HIV データセット（41,913分子）→ HIV複製阻害
- モデル形式: MultitaskRegressor/Classifier + CircularFingerprint(ECFP4)

---

## Flutter CanvasKit の注意点（Playwright テスト用）

Flutter Web の CanvasKit レンダラーは **HTML DOM に実際の input 要素を生成しない**。
Playwright でのテストは `page.locator('input')` が使えず、**座標ベースのクリック**が必要。

### 確認済み座標（1400×900 viewport）

| 要素 | X | Y |
|------|---|---|
| Nav: Home | 38 | 100 |
| Nav: Predict | 38 | 160 |
| Nav: Batch | 38 | 220 |
| Nav: Compare | 38 | 280 |
| Nav: Search | 38 | 340 |
| Predict 入力フィールド | 660 | 465 |
| Predict ボタン | 1290 | 465 |
| Batch テキストエリア | 730 | 215 |
| Batch「Run Batch」ボタン | 330 | 110 |
| Compare 分子1入力 | 363 | 480 |
| Compare 分子2入力 | 945 | 480 |
| Compare「Compare」ボタン | 1287 | 468 |
| Search 入力フィールド | 630 | 395 |

---

## Flutter ビルド方法

```bash
# Flutter SDK: C:\Users\takay\flutter\bin\flutter
export PATH="$PATH:/c/Users/takay/flutter/bin"

cd C:\Users\takay\python379\DeepChem\mol_app
flutter build web --release

# ビルド後、APIポートを確認（build/web/main.dart.js 内に埋め込まれる）
# app_config.dart で apiBaseUrl = 'http://localhost:8282' に設定済み
```

---

## VS Code 設定

Dart拡張のFlutter SDKパスが壊れている場合：
```json
// settings.json
"dart.flutterSdkPath": "C:\\Users\\takay\\flutter"
```

---

## サンプルCSV（バッチテスト用）

`sample_batch.csv` — 10分子（Aspirin, Paracetamol, Caffeine, Ibuprofen, Dopamine, Serotonin, Glucose, Metformin, Penicillin G, Ethanol）

---

## ドキュメント

`docs/index.html` — 日本語の詳細ドキュメント（薄紫テーマ）をブラウザで直接開ける。
