# DeepChem MolAI — Flutter Web Frontend

Flutter Web frontend for ADMET property prediction (RDKit + mock ML).

## Backend

- Repo: https://github.com/tkyk-mcst/deepchem-molai-backend
- Demo API: https://deepchem-api.onrender.com
- Demo App: https://deepchem-molai.vercel.app

## Setup

```bash
flutter pub get
flutter build web --release
```

Change API URL in `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:8282';
```

## Features

- Predict: SMILES → ADMET properties (MW, logP, TPSA, QED, SA Score, BBB, hERG, CYP3A4, PAINS/Brenk)
- Batch: Up to 100 molecules
- Compare: Tanimoto similarity + property diff
- Search: PubChem name search

## Notes

- Mock ML predictions (formula-based, not trained models)
- For real DeepChem models, replace mock_backend.py with deepchem-api/
