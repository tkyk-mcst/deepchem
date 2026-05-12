import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DeepChem'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPredict.
  ///
  /// In en, this message translates to:
  /// **'Predict'**
  String get navPredict;

  /// No description provided for @navBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get navBatch;

  /// No description provided for @navCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get navCompare;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navGaOpt.
  ///
  /// In en, this message translates to:
  /// **'GA Opt'**
  String get navGaOpt;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'DeepChem'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive molecular property prediction powered by DeepChem & RDKit.\nPredict solubility, BBB permeability, toxicity, drug-likeness and more.'**
  String get homeSubtitle;

  /// No description provided for @homeInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter SMILES (e.g. CC(=O)Oc1ccccc1C(=O)O)'**
  String get homeInputHint;

  /// No description provided for @homePredictButton.
  ///
  /// In en, this message translates to:
  /// **'Predict'**
  String get homePredictButton;

  /// No description provided for @homeSampleMolecules.
  ///
  /// In en, this message translates to:
  /// **'Sample Molecules'**
  String get homeSampleMolecules;

  /// No description provided for @homeClickToPredict.
  ///
  /// In en, this message translates to:
  /// **'Click to predict'**
  String get homeClickToPredict;

  /// No description provided for @predictTitle.
  ///
  /// In en, this message translates to:
  /// **'Predict Properties'**
  String get predictTitle;

  /// No description provided for @predictSmilesLabel.
  ///
  /// In en, this message translates to:
  /// **'SMILES'**
  String get predictSmilesLabel;

  /// No description provided for @predictHint.
  ///
  /// In en, this message translates to:
  /// **'Enter SMILES…'**
  String get predictHint;

  /// No description provided for @predictButton.
  ///
  /// In en, this message translates to:
  /// **'Predict'**
  String get predictButton;

  /// No description provided for @predictLoading.
  ///
  /// In en, this message translates to:
  /// **'Computing…'**
  String get predictLoading;

  /// No description provided for @predictExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get predictExamples;

  /// No description provided for @predictEnterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter SMILES to predict'**
  String get predictEnterPrompt;

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Prediction'**
  String get batchTitle;

  /// No description provided for @batchUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV or paste SMILES (one per line)'**
  String get batchUploadHint;

  /// No description provided for @batchUploadCsv.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV'**
  String get batchUploadCsv;

  /// No description provided for @batchRun.
  ///
  /// In en, this message translates to:
  /// **'Run Batch'**
  String get batchRun;

  /// No description provided for @batchRunning.
  ///
  /// In en, this message translates to:
  /// **'Running...'**
  String get batchRunning;

  /// No description provided for @batchProgress.
  ///
  /// In en, this message translates to:
  /// **'Processing {current} / {total} molecules...'**
  String batchProgress(int current, int total);

  /// No description provided for @batchResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String batchResults(int count);

  /// No description provided for @batchSort.
  ///
  /// In en, this message translates to:
  /// **'Sort: '**
  String get batchSort;

  /// No description provided for @batchColStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get batchColStructure;

  /// No description provided for @batchColSmiles.
  ///
  /// In en, this message translates to:
  /// **'SMILES'**
  String get batchColSmiles;

  /// No description provided for @batchColMw.
  ///
  /// In en, this message translates to:
  /// **'MW'**
  String get batchColMw;

  /// No description provided for @batchColLogp.
  ///
  /// In en, this message translates to:
  /// **'LogP'**
  String get batchColLogp;

  /// No description provided for @batchColQed.
  ///
  /// In en, this message translates to:
  /// **'QED'**
  String get batchColQed;

  /// No description provided for @batchColLogs.
  ///
  /// In en, this message translates to:
  /// **'logS'**
  String get batchColLogs;

  /// No description provided for @batchColBbb.
  ///
  /// In en, this message translates to:
  /// **'BBB%'**
  String get batchColBbb;

  /// No description provided for @batchColDrugLike.
  ///
  /// In en, this message translates to:
  /// **'Drug-Like'**
  String get batchColDrugLike;

  /// No description provided for @batchColAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get batchColAlerts;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Molecule Comparison'**
  String get compareTitle;

  /// No description provided for @compareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare two molecules side-by-side'**
  String get compareSubtitle;

  /// No description provided for @compareMol1Label.
  ///
  /// In en, this message translates to:
  /// **'Molecule 1'**
  String get compareMol1Label;

  /// No description provided for @compareMol1Hint.
  ///
  /// In en, this message translates to:
  /// **'SMILES for molecule 1'**
  String get compareMol1Hint;

  /// No description provided for @compareMol2Label.
  ///
  /// In en, this message translates to:
  /// **'Molecule 2'**
  String get compareMol2Label;

  /// No description provided for @compareMol2Hint.
  ///
  /// In en, this message translates to:
  /// **'SMILES for molecule 2'**
  String get compareMol2Hint;

  /// No description provided for @compareButton.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compareButton;

  /// No description provided for @compareTanimoto.
  ///
  /// In en, this message translates to:
  /// **'Tanimoto Similarity: '**
  String get compareTanimoto;

  /// No description provided for @compareColProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get compareColProperty;

  /// No description provided for @compareColMol1.
  ///
  /// In en, this message translates to:
  /// **'Molecule 1'**
  String get compareColMol1;

  /// No description provided for @compareColDelta.
  ///
  /// In en, this message translates to:
  /// **'Δ'**
  String get compareColDelta;

  /// No description provided for @compareColMol2.
  ///
  /// In en, this message translates to:
  /// **'Molecule 2'**
  String get compareColMol2;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'PubChem Search'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search compounds by name and get SMILES from PubChem'**
  String get searchSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. aspirin, caffeine, ibuprofen, glucose...'**
  String get searchHint;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search PubChem'**
  String get searchButton;

  /// No description provided for @searchFoundResults.
  ///
  /// In en, this message translates to:
  /// **'Found {count} result(s)'**
  String searchFoundResults(int count);

  /// No description provided for @searchQuickSearch.
  ///
  /// In en, this message translates to:
  /// **'Quick Search'**
  String get searchQuickSearch;

  /// No description provided for @searchPredictButton.
  ///
  /// In en, this message translates to:
  /// **'Predict Properties'**
  String get searchPredictButton;

  /// No description provided for @optimizeTitle.
  ///
  /// In en, this message translates to:
  /// **'SELFIES Genetic Algorithm'**
  String get optimizeTitle;

  /// No description provided for @optimizeSeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed molecules (SMILES, one per line)'**
  String get optimizeSeedLabel;

  /// No description provided for @optimizeShowSeedProps.
  ///
  /// In en, this message translates to:
  /// **'Show seed properties'**
  String get optimizeShowSeedProps;

  /// No description provided for @optimizePopSize.
  ///
  /// In en, this message translates to:
  /// **'Pop. size'**
  String get optimizePopSize;

  /// No description provided for @optimizeGenerations.
  ///
  /// In en, this message translates to:
  /// **'Generations'**
  String get optimizeGenerations;

  /// No description provided for @optimizeObjectives.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get optimizeObjectives;

  /// No description provided for @optimizeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get optimizeAdd;

  /// No description provided for @optimizeStart.
  ///
  /// In en, this message translates to:
  /// **'Start Optimization'**
  String get optimizeStart;

  /// No description provided for @optimizeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get optimizeSubmitting;

  /// No description provided for @optimizeRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get optimizeRunning;

  /// No description provided for @optimizeEvolving.
  ///
  /// In en, this message translates to:
  /// **'Evolving molecules…'**
  String get optimizeEvolving;

  /// No description provided for @optimizeCandidates.
  ///
  /// In en, this message translates to:
  /// **'{count} candidates'**
  String optimizeCandidates(int count);

  /// No description provided for @optimizeCopySelfies.
  ///
  /// In en, this message translates to:
  /// **'Copy SELFIES'**
  String get optimizeCopySelfies;

  /// No description provided for @optimizePending.
  ///
  /// In en, this message translates to:
  /// **'Pending…'**
  String get optimizePending;

  /// No description provided for @optimizeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get optimizeDone;

  /// No description provided for @optimizeFoundCandidates.
  ///
  /// In en, this message translates to:
  /// **'{count} candidates found'**
  String optimizeFoundCandidates(int count);

  /// No description provided for @optimizeError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get optimizeError;

  /// No description provided for @optimizeSetParams.
  ///
  /// In en, this message translates to:
  /// **'Set parameters and start optimization'**
  String get optimizeSetParams;

  /// No description provided for @optimizeSelfiesDesc.
  ///
  /// In en, this message translates to:
  /// **'SELFIES strings evolved via genetic algorithm'**
  String get optimizeSelfiesDesc;

  /// No description provided for @optimizeJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job: {id}'**
  String optimizeJobLabel(String id);

  /// No description provided for @cardMolDescriptors.
  ///
  /// In en, this message translates to:
  /// **'Molecular Descriptors'**
  String get cardMolDescriptors;

  /// No description provided for @cardDrugLikeness.
  ///
  /// In en, this message translates to:
  /// **'Drug-Likeness'**
  String get cardDrugLikeness;

  /// No description provided for @cardMlPredictions.
  ///
  /// In en, this message translates to:
  /// **'ML Model Predictions'**
  String get cardMlPredictions;

  /// No description provided for @cardStructuralAlerts.
  ///
  /// In en, this message translates to:
  /// **'Structural Alerts'**
  String get cardStructuralAlerts;

  /// No description provided for @cardDrugLike.
  ///
  /// In en, this message translates to:
  /// **'Drug-Like ({n} violations)'**
  String cardDrugLike(int n);

  /// No description provided for @cardNotDrugLike.
  ///
  /// In en, this message translates to:
  /// **'Not Drug-Like ({n} violations)'**
  String cardNotDrugLike(int n);

  /// No description provided for @cardNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No structural alerts'**
  String get cardNoAlerts;

  /// No description provided for @cardAlertsFound.
  ///
  /// In en, this message translates to:
  /// **'{n} alert(s) found'**
  String cardAlertsFound(int n);

  /// No description provided for @cardPainsLabel.
  ///
  /// In en, this message translates to:
  /// **'PAINS:'**
  String get cardPainsLabel;

  /// No description provided for @cardBrenkLabel.
  ///
  /// In en, this message translates to:
  /// **'Brenk:'**
  String get cardBrenkLabel;

  /// No description provided for @cardSolubility.
  ///
  /// In en, this message translates to:
  /// **'Aqueous Solubility'**
  String get cardSolubility;

  /// No description provided for @cardBbbp.
  ///
  /// In en, this message translates to:
  /// **'BBB Permeability'**
  String get cardBbbp;

  /// No description provided for @cardBace.
  ///
  /// In en, this message translates to:
  /// **'BACE-1 Inhibition'**
  String get cardBace;

  /// No description provided for @cardHiv.
  ///
  /// In en, this message translates to:
  /// **'HIV Activity'**
  String get cardHiv;

  /// No description provided for @cardTox21.
  ///
  /// In en, this message translates to:
  /// **'Tox21 Endpoints'**
  String get cardTox21;

  /// No description provided for @cardClinTox.
  ///
  /// In en, this message translates to:
  /// **'ClinTox'**
  String get cardClinTox;

  /// No description provided for @cardSider.
  ///
  /// In en, this message translates to:
  /// **'SIDER Side Effects'**
  String get cardSider;

  /// No description provided for @cardMuv.
  ///
  /// In en, this message translates to:
  /// **'MUV Bioassays'**
  String get cardMuv;

  /// No description provided for @cardFreesolv.
  ///
  /// In en, this message translates to:
  /// **'Hydration Free Energy'**
  String get cardFreesolv;

  /// No description provided for @cardLipo.
  ///
  /// In en, this message translates to:
  /// **'Lipophilicity (logD)'**
  String get cardLipo;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonScore.
  ///
  /// In en, this message translates to:
  /// **'score'**
  String get commonScore;

  /// No description provided for @commonWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight: {w}'**
  String commonWeightLabel(String w);

  /// No description provided for @commonTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get commonTarget;

  /// No description provided for @commonNoMolecule.
  ///
  /// In en, this message translates to:
  /// **'No molecule'**
  String get commonNoMolecule;

  /// No description provided for @commonFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula: '**
  String get commonFormula;

  /// No description provided for @commonPubchemCid.
  ///
  /// In en, this message translates to:
  /// **'PubChem CID: '**
  String get commonPubchemCid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
