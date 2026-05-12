// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DeepChem';

  @override
  String get navHome => 'Home';

  @override
  String get navPredict => 'Predict';

  @override
  String get navBatch => 'Batch';

  @override
  String get navCompare => 'Compare';

  @override
  String get navSearch => 'Search';

  @override
  String get navGaOpt => 'GA Opt';

  @override
  String get homeHeadline => 'DeepChem';

  @override
  String get homeSubtitle =>
      'Comprehensive molecular property prediction powered by DeepChem & RDKit.\nPredict solubility, BBB permeability, toxicity, drug-likeness and more.';

  @override
  String get homeInputHint => 'Enter SMILES (e.g. CC(=O)Oc1ccccc1C(=O)O)';

  @override
  String get homePredictButton => 'Predict';

  @override
  String get homeSampleMolecules => 'Sample Molecules';

  @override
  String get homeClickToPredict => 'Click to predict';

  @override
  String get predictTitle => 'Predict Properties';

  @override
  String get predictSmilesLabel => 'SMILES';

  @override
  String get predictHint => 'Enter SMILES…';

  @override
  String get predictButton => 'Predict';

  @override
  String get predictLoading => 'Computing…';

  @override
  String get predictExamples => 'Examples';

  @override
  String get predictEnterPrompt => 'Enter SMILES to predict';

  @override
  String get batchTitle => 'Batch Prediction';

  @override
  String get batchUploadHint => 'Upload CSV or paste SMILES (one per line)';

  @override
  String get batchUploadCsv => 'Upload CSV';

  @override
  String get batchRun => 'Run Batch';

  @override
  String get batchRunning => 'Running...';

  @override
  String batchProgress(int current, int total) {
    return 'Processing $current / $total molecules...';
  }

  @override
  String batchResults(int count) {
    return '$count results';
  }

  @override
  String get batchSort => 'Sort: ';

  @override
  String get batchColStructure => 'Structure';

  @override
  String get batchColSmiles => 'SMILES';

  @override
  String get batchColMw => 'MW';

  @override
  String get batchColLogp => 'LogP';

  @override
  String get batchColQed => 'QED';

  @override
  String get batchColLogs => 'logS';

  @override
  String get batchColBbb => 'BBB%';

  @override
  String get batchColDrugLike => 'Drug-Like';

  @override
  String get batchColAlerts => 'Alerts';

  @override
  String get compareTitle => 'Molecule Comparison';

  @override
  String get compareSubtitle => 'Compare two molecules side-by-side';

  @override
  String get compareMol1Label => 'Molecule 1';

  @override
  String get compareMol1Hint => 'SMILES for molecule 1';

  @override
  String get compareMol2Label => 'Molecule 2';

  @override
  String get compareMol2Hint => 'SMILES for molecule 2';

  @override
  String get compareButton => 'Compare';

  @override
  String get compareTanimoto => 'Tanimoto Similarity: ';

  @override
  String get compareColProperty => 'Property';

  @override
  String get compareColMol1 => 'Molecule 1';

  @override
  String get compareColDelta => 'Δ';

  @override
  String get compareColMol2 => 'Molecule 2';

  @override
  String get searchTitle => 'PubChem Search';

  @override
  String get searchSubtitle =>
      'Search compounds by name and get SMILES from PubChem';

  @override
  String get searchHint => 'e.g. aspirin, caffeine, ibuprofen, glucose...';

  @override
  String get searchButton => 'Search PubChem';

  @override
  String searchFoundResults(int count) {
    return 'Found $count result(s)';
  }

  @override
  String get searchQuickSearch => 'Quick Search';

  @override
  String get searchPredictButton => 'Predict Properties';

  @override
  String get optimizeTitle => 'SELFIES Genetic Algorithm';

  @override
  String get optimizeSeedLabel => 'Seed molecules (SMILES, one per line)';

  @override
  String get optimizeShowSeedProps => 'Show seed properties';

  @override
  String get optimizePopSize => 'Pop. size';

  @override
  String get optimizeGenerations => 'Generations';

  @override
  String get optimizeObjectives => 'Objectives';

  @override
  String get optimizeAdd => 'Add';

  @override
  String get optimizeStart => 'Start Optimization';

  @override
  String get optimizeSubmitting => 'Submitting…';

  @override
  String get optimizeRunning => 'Running…';

  @override
  String get optimizeEvolving => 'Evolving molecules…';

  @override
  String optimizeCandidates(int count) {
    return '$count candidates';
  }

  @override
  String get optimizeCopySelfies => 'Copy SELFIES';

  @override
  String get optimizePending => 'Pending…';

  @override
  String get optimizeDone => 'Done';

  @override
  String optimizeFoundCandidates(int count) {
    return '$count candidates found';
  }

  @override
  String get optimizeError => 'Error';

  @override
  String get optimizeSetParams => 'Set parameters and start optimization';

  @override
  String get optimizeSelfiesDesc =>
      'SELFIES strings evolved via genetic algorithm';

  @override
  String optimizeJobLabel(String id) {
    return 'Job: $id';
  }

  @override
  String get cardMolDescriptors => 'Molecular Descriptors';

  @override
  String get cardDrugLikeness => 'Drug-Likeness';

  @override
  String get cardMlPredictions => 'ML Model Predictions';

  @override
  String get cardStructuralAlerts => 'Structural Alerts';

  @override
  String cardDrugLike(int n) {
    return 'Drug-Like ($n violations)';
  }

  @override
  String cardNotDrugLike(int n) {
    return 'Not Drug-Like ($n violations)';
  }

  @override
  String get cardNoAlerts => 'No structural alerts';

  @override
  String cardAlertsFound(int n) {
    return '$n alert(s) found';
  }

  @override
  String get cardPainsLabel => 'PAINS:';

  @override
  String get cardBrenkLabel => 'Brenk:';

  @override
  String get cardSolubility => 'Aqueous Solubility';

  @override
  String get cardBbbp => 'BBB Permeability';

  @override
  String get cardBace => 'BACE-1 Inhibition';

  @override
  String get cardHiv => 'HIV Activity';

  @override
  String get cardTox21 => 'Tox21 Endpoints';

  @override
  String get cardClinTox => 'ClinTox';

  @override
  String get cardSider => 'SIDER Side Effects';

  @override
  String get cardMuv => 'MUV Bioassays';

  @override
  String get cardFreesolv => 'Hydration Free Energy';

  @override
  String get cardLipo => 'Lipophilicity (logD)';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonScore => 'score';

  @override
  String commonWeightLabel(String w) {
    return 'Weight: $w';
  }

  @override
  String get commonTarget => 'Target';

  @override
  String get commonNoMolecule => 'No molecule';

  @override
  String get commonFormula => 'Formula: ';

  @override
  String get commonPubchemCid => 'PubChem CID: ';
}
