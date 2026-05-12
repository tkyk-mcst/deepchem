# DeepChem MolAI — ADMET Prediction Web App

SMILES を入力するだけで、分子の薬物動態・毒性・物性を AI が予測する Flutter Web アプリ。

- **バックエンド**: FastAPI + RDKit（モック版）/ DeepChem（本番版）
- **フロントエンド**: Flutter Web (CanvasKit)
- **対象**: 創薬研究者・化学エンジニア向け

---

## 画面一覧

| メニュー | 内容 |
|---|---|
| Home | サンプル分子グリッド（クリックで予測画面へ） |
| Predict | SMILES → ADMET 全項目予測 + 構造画像 + アラート |
| Batch | 最大 100 分子の一括予測（CSV 貼付け対応） |
| Compare | 2 分子の Tanimoto 類似度 + 物性差分 |
| Search | PubChem 名前検索 → SMILES 取得 → 即時予測 |

---

## アーキテクチャ

```
ブラウザ (Flutter Web / CanvasKit)
    ↕ HTTP/JSON  localhost:8282
mock_backend.py (FastAPI + RDKit)   ← 開発・評価用（DeepChem不要）
    または
deepchem-api/main.py (FastAPI + DeepChem)  ← 本番用（GPU推奨）
    ↕ HTTPS (Search機能のみ)
pubchem.ncbi.nlm.nih.gov
```

---

## ローカル起動手順（モック版・推奨）

DeepChem なしで全機能を試せるモックバックエンドです。

### 前提条件

- Python 3.10 以上
- pip

### 1. リポジトリをクローン

```bash
git clone https://github.com/tkyk-mcst/deepchem.git
cd deepchem
```

### 2. バックエンドを起動

```bash
pip install -r requirements.txt
uvicorn mock_backend:app --host 0.0.0.0 --port 8282
```

> **RDKit について**: `pip install rdkit` で入らない場合は Conda を使う。
> ```bash
> conda install -c conda-forge rdkit
> ```

### 3. フロントエンドを配信

別ターミナルで:

```bash
cd mol_app/build/web
python -m http.server 3000
```

ブラウザで `http://localhost:3000` を開く。

### Windows の場合（一括起動）

`start.bat` をダブルクリックするか:

```cmd
start.bat
```

---

## ローカル起動手順（DeepChem 本番版）

実際の ML モデル（DeepChem）を使いたい場合。

```bash
cd deepchem-api
pip install -r requirements.txt

# モデルを学習（初回のみ、GPU推奨、数分かかる）
python train_models.py

# サーバー起動
uvicorn main:app --host 0.0.0.0 --port 8282
```

フロントエンドは同じ手順（ポート 3000）。

---

## API ドキュメント

バックエンド起動後: `http://localhost:8282/docs` (Swagger UI)

主なエンドポイント:

| エンドポイント | メソッド | 説明 |
|---|---|---|
| `/predict` | POST | 単一分子の ADMET 予測 |
| `/predict/batch` | POST | 複数分子の一括予測 |
| `/molecule/compare` | POST | 2分子比較（Tanimoto） |
| `/molecule/image` | GET | 分子構造 SVG 画像 |
| `/molecule/variants` | GET | 構造アナログ生成 |
| `/molecule/alerts` | GET | PAINS / Brenk アラート |
| `/pubchem/search` | GET | PubChem 名前検索 |

---

## 予測項目一覧

### RDKit で実計算（モック版・本番版 共通）

| 項目 | 説明 |
|---|---|
| 分子量 (MW) | g/mol |
| LogP | 脂溶性 |
| TPSA | 極性表面積 |
| HBD / HBA | 水素結合ドナー / アクセプター |
| 回転可能結合数 | |
| Fsp3 | sp3 炭素割合 |
| QED | Drug-likeness スコア |
| PAINS / Brenk | 構造アラート（創薬注意フラグ） |

### ML 予測

| 項目 | モック版 | 本番版（DeepChem） |
|---|---|---|
| 水溶性 (logS) | 数式近似 | Delaney データセット (1,128分子) |
| 血液脳関門 (BBBP) | sigmoid近似 | BBBP データセット (2,050分子) |
| Tox21 毒性 | ベータ分布 | Tox21 (8,014分子) × 12エンドポイント |
| ClinTox | ベータ分布 | ClinTox (1,491分子) |
| HIV阻害 | ベータ分布 | HIV データセット (41,913分子) |

---

## フロントエンドをビルドし直す場合

API の URL を変更したいとき（デフォルト: `http://localhost:8282`）は再ビルドが必要:

```bash
# 1. API URL を変更
#    mol_app/lib/config/app_config.dart
#    static const String apiBaseUrl = 'http://your-server:8282';

# 2. ビルド
cd mol_app
flutter pub get
flutter build web --release
# → mol_app/build/web/ に生成される
```

---

## ディレクトリ構成

```
deepchem/
├── mock_backend.py            ← ★ モックバックエンド（RDKit + 数式ML）
├── requirements.txt           ← モック版の依存パッケージ
├── sample_batch.csv           ← バッチ予測サンプル（10分子）
│
├── deepchem-api/              ← 本番バックエンド（DeepChem使用）
│   ├── main.py                ← FastAPI エントリポイント
│   ├── predictor.py           ← DeepChem 予測ロジック
│   ├── train_models.py        ← モデル学習スクリプト
│   └── requirements.txt       ← 本番版の依存パッケージ
│
└── mol_app/                   ← Flutter Web フロントエンド
    ├── lib/
    │   ├── main.dart
    │   ├── config/app_config.dart    ← API URL 設定
    │   └── screens/
    │       ├── predict_screen.dart
    │       ├── batch_screen.dart
    │       ├── compare_screen.dart
    │       └── search_screen.dart
    └── build/web/             ← ビルド済み（そのまま配信可）
```

---

## ライセンス

- RDKit: BSD
- DeepChem: MIT
- Flutter: BSD
