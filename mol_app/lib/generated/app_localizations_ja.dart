// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'DeepChem';

  @override
  String get navHome => 'ホーム';

  @override
  String get navPredict => '予測';

  @override
  String get navBatch => 'バッチ';

  @override
  String get navCompare => '比較';

  @override
  String get navSearch => '検索';

  @override
  String get navGaOpt => 'GA最適化';

  @override
  String get homeHeadline => 'DeepChem';

  @override
  String get homeSubtitle =>
      'DeepChem & RDKit による包括的な分子物性予測ツール。\n水溶性・血液脳関門透過性・毒性・薬物様性などを予測。';

  @override
  String get homeInputHint => 'SMILESを入力 (例: CC(=O)Oc1ccccc1C(=O)O)';

  @override
  String get homePredictButton => '予測';

  @override
  String get homeSampleMolecules => 'サンプル分子';

  @override
  String get homeClickToPredict => 'クリックして予測';

  @override
  String get predictTitle => '物性予測';

  @override
  String get predictSmilesLabel => 'SMILES';

  @override
  String get predictHint => 'SMILESを入力…';

  @override
  String get predictButton => '予測';

  @override
  String get predictLoading => '計算中…';

  @override
  String get predictExamples => '例';

  @override
  String get predictEnterPrompt => 'SMILESを入力して予測してください';

  @override
  String get batchTitle => 'バッチ予測';

  @override
  String get batchUploadHint => 'CSVをアップロード、またはSMILESを1行ずつ貼り付け';

  @override
  String get batchUploadCsv => 'CSV読み込み';

  @override
  String get batchRun => 'バッチ実行';

  @override
  String get batchRunning => '実行中...';

  @override
  String batchProgress(int current, int total) {
    return '$current / $total 分子を処理中...';
  }

  @override
  String batchResults(int count) {
    return '$count 件の結果';
  }

  @override
  String get batchSort => 'ソート: ';

  @override
  String get batchColStructure => '構造';

  @override
  String get batchColSmiles => 'SMILES';

  @override
  String get batchColMw => '分子量';

  @override
  String get batchColLogp => 'LogP';

  @override
  String get batchColQed => 'QED';

  @override
  String get batchColLogs => 'logS';

  @override
  String get batchColBbb => 'BBB%';

  @override
  String get batchColDrugLike => '薬物様性';

  @override
  String get batchColAlerts => 'アラート';

  @override
  String get compareTitle => '分子比較';

  @override
  String get compareSubtitle => '2つの分子を並べて比較';

  @override
  String get compareMol1Label => '分子1';

  @override
  String get compareMol1Hint => '分子1のSMILES';

  @override
  String get compareMol2Label => '分子2';

  @override
  String get compareMol2Hint => '分子2のSMILES';

  @override
  String get compareButton => '比較';

  @override
  String get compareTanimoto => 'タニモト類似度: ';

  @override
  String get compareColProperty => '物性';

  @override
  String get compareColMol1 => '分子1';

  @override
  String get compareColDelta => '差分';

  @override
  String get compareColMol2 => '分子2';

  @override
  String get searchTitle => 'PubChem検索';

  @override
  String get searchSubtitle => '化合物名でPubChemを検索してSMILESを取得';

  @override
  String get searchHint => '例: aspirin, caffeine, ibuprofen, glucose...';

  @override
  String get searchButton => 'PubChem検索';

  @override
  String searchFoundResults(int count) {
    return '$count 件見つかりました';
  }

  @override
  String get searchQuickSearch => 'クイック検索';

  @override
  String get searchPredictButton => '物性を予測';

  @override
  String get optimizeTitle => 'SELFIES 遺伝的アルゴリズム';

  @override
  String get optimizeSeedLabel => 'シード分子（SMILES、1行1分子）';

  @override
  String get optimizeShowSeedProps => 'シード物性を表示';

  @override
  String get optimizePopSize => '個体数';

  @override
  String get optimizeGenerations => '世代数';

  @override
  String get optimizeObjectives => '目標関数';

  @override
  String get optimizeAdd => '追加';

  @override
  String get optimizeStart => '最適化開始';

  @override
  String get optimizeSubmitting => '送信中…';

  @override
  String get optimizeRunning => '実行中…';

  @override
  String get optimizeEvolving => '分子を進化中…';

  @override
  String optimizeCandidates(int count) {
    return '$count 候補';
  }

  @override
  String get optimizeCopySelfies => 'SELFIESをコピー';

  @override
  String get optimizePending => '待機中…';

  @override
  String get optimizeDone => '完了';

  @override
  String optimizeFoundCandidates(int count) {
    return '$count 候補を発見';
  }

  @override
  String get optimizeError => 'エラー';

  @override
  String get optimizeSetParams => 'パラメータを設定して最適化を開始';

  @override
  String get optimizeSelfiesDesc => '遺伝的アルゴリズムでSELFIES文字列を進化';

  @override
  String optimizeJobLabel(String id) {
    return 'ジョブ: $id';
  }

  @override
  String get cardMolDescriptors => '分子記述子';

  @override
  String get cardDrugLikeness => '薬物様性';

  @override
  String get cardMlPredictions => 'MLモデル予測';

  @override
  String get cardStructuralAlerts => '構造アラート';

  @override
  String cardDrugLike(int n) {
    return '薬物様 ($n 違反)';
  }

  @override
  String cardNotDrugLike(int n) {
    return '非薬物様 ($n 違反)';
  }

  @override
  String get cardNoAlerts => '構造アラートなし';

  @override
  String cardAlertsFound(int n) {
    return '$n 件のアラートを検出';
  }

  @override
  String get cardPainsLabel => 'PAINS:';

  @override
  String get cardBrenkLabel => 'Brenk:';

  @override
  String get cardSolubility => '水溶性';

  @override
  String get cardBbbp => '血液脳関門透過性';

  @override
  String get cardBace => 'BACE-1阻害';

  @override
  String get cardHiv => 'HIV活性';

  @override
  String get cardTox21 => 'Tox21毒性エンドポイント';

  @override
  String get cardClinTox => '臨床毒性';

  @override
  String get cardSider => 'SIDER副作用';

  @override
  String get cardMuv => 'MUVバイオアッセイ';

  @override
  String get cardFreesolv => '水和自由エネルギー';

  @override
  String get cardLipo => '親油性 (logD)';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonScore => 'スコア';

  @override
  String commonWeightLabel(String w) {
    return '重み: $w';
  }

  @override
  String get commonTarget => '目標値';

  @override
  String get commonNoMolecule => '分子なし';

  @override
  String get commonFormula => '分子式: ';

  @override
  String get commonPubchemCid => 'PubChem CID: ';
}
