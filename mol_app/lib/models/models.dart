// Data models for the Molecular Properties API

class PredictionResult {
  final String smiles;
  final String? canonicalSmiles;
  final bool valid;
  final String? error;
  final Map<String, dynamic>? descriptors;
  final Map<String, dynamic>? drugLikeness;
  final Map<String, dynamic>? alerts;
  final Map<String, dynamic>? predictions;
  final List<String> modelsLoaded;

  PredictionResult({
    required this.smiles,
    this.canonicalSmiles,
    required this.valid,
    this.error,
    this.descriptors,
    this.drugLikeness,
    this.alerts,
    this.predictions,
    this.modelsLoaded = const [],
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      smiles: json['smiles'] ?? '',
      canonicalSmiles: json['canonical_smiles'],
      valid: json['valid'] ?? false,
      error: json['error'],
      descriptors: json['descriptors'],
      drugLikeness: json['drug_likeness'],
      alerts: json['alerts'],
      predictions: json['predictions'],
      modelsLoaded: List<String>.from(json['models_loaded'] ?? []),
    );
  }

  // Compute ADMET radar values (0-1 normalized)
  Map<String, double> get radarValues {
    final result = <String, double>{};
    final preds = predictions ?? {};
    final dl = drugLikeness ?? {};

    // Solubility: map logS (-7 to 0) → (0 to 1)
    if (preds['solubility'] != null) {
      final logS = (preds['solubility']['logS'] as num?)?.toDouble() ?? -5.0;
      result['Solubility'] = ((logS + 7) / 7).clamp(0.0, 1.0);
    }

    // BBBP: probability of permeability
    if (preds['bbbp'] != null) {
      result['BBB'] = (preds['bbbp']['probability'] as num?)?.toDouble() ?? 0.0;
    }

    // HIV: inactivity = 1 - active_prob
    if (preds['hiv'] != null) {
      final hivProb = (preds['hiv']['probability'] as num?)?.toDouble() ?? 0.0;
      result['HIV Safety'] = 1.0 - hivProb;
    }

    // Tox21: safety = 1 - max toxic prob
    if (preds['tox21'] != null) {
      final toxMap = preds['tox21'] as Map<String, dynamic>;
      double maxTox = 0.0;
      for (final v in toxMap.values) {
        final p = (v['probability'] as num?)?.toDouble() ?? 0.0;
        if (p > maxTox) maxTox = p;
      }
      result['Tox21 Safety'] = 1.0 - maxTox;
    }

    // ClinTox: safety = 1 - prob
    if (preds['clintox'] != null) {
      final ctMap = preds['clintox'] as Map<String, dynamic>;
      double maxCT = 0.0;
      for (final v in ctMap.values) {
        final p = (v['probability'] as num?)?.toDouble() ?? 0.0;
        if (p > maxCT) maxCT = p;
      }
      result['ClinTox Safety'] = 1.0 - maxCT;
    }

    // QED
    final qed = (dl['qed'] as num?)?.toDouble();
    if (qed != null) result['QED'] = qed;

    // Lipinski
    final violations = (dl['violations'] as num?)?.toInt() ?? 4;
    result['Lipinski'] = (1.0 - violations / 4.0).clamp(0.0, 1.0);

    return result;
  }
}

class SampleMolecule {
  final String name;
  final String smiles;
  final String description;
  final String? category;

  SampleMolecule({
    required this.name,
    required this.smiles,
    required this.description,
    this.category,
  });

  factory SampleMolecule.fromJson(Map<String, dynamic> json) {
    return SampleMolecule(
      name: json['name'] ?? '',
      smiles: json['smiles'] ?? '',
      description: json['description'] ?? '',
      category: json['category'],
    );
  }
}

class PubChemResult {
  final int? cid;
  final String smiles;
  final String formula;
  final dynamic mw;
  final String iupac;

  PubChemResult({
    this.cid,
    required this.smiles,
    required this.formula,
    this.mw,
    required this.iupac,
  });

  factory PubChemResult.fromJson(Map<String, dynamic> json) {
    return PubChemResult(
      cid: json['cid'],
      smiles: json['smiles'] ?? '',
      formula: json['formula'] ?? '',
      mw: json['mw'],
      iupac: json['iupac'] ?? '',
    );
  }
}
