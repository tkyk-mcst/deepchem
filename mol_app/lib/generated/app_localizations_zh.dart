// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DeepChem';

  @override
  String get navHome => '主页';

  @override
  String get navPredict => '预测';

  @override
  String get navBatch => '批量';

  @override
  String get navCompare => '比较';

  @override
  String get navSearch => '搜索';

  @override
  String get navGaOpt => 'GA优化';

  @override
  String get homeHeadline => 'DeepChem';

  @override
  String get homeSubtitle =>
      '基于 DeepChem & RDKit 的综合分子性质预测工具。\n预测水溶性、血脑屏障透过性、毒性、类药性等。';

  @override
  String get homeInputHint => '输入SMILES（例：CC(=O)Oc1ccccc1C(=O)O）';

  @override
  String get homePredictButton => '预测';

  @override
  String get homeSampleMolecules => '示例分子';

  @override
  String get homeClickToPredict => '点击预测';

  @override
  String get predictTitle => '性质预测';

  @override
  String get predictSmilesLabel => 'SMILES';

  @override
  String get predictHint => '输入SMILES…';

  @override
  String get predictButton => '预测';

  @override
  String get predictLoading => '计算中…';

  @override
  String get predictExamples => '示例';

  @override
  String get predictEnterPrompt => '输入SMILES进行预测';

  @override
  String get batchTitle => '批量预测';

  @override
  String get batchUploadHint => '上传CSV或逐行粘贴SMILES';

  @override
  String get batchUploadCsv => '上传CSV';

  @override
  String get batchRun => '批量运行';

  @override
  String get batchRunning => '运行中...';

  @override
  String batchProgress(int current, int total) {
    return '正在处理第 $current / $total 个分子...';
  }

  @override
  String batchResults(int count) {
    return '$count 条结果';
  }

  @override
  String get batchSort => '排序: ';

  @override
  String get batchColStructure => '结构';

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
  String get batchColDrugLike => '类药性';

  @override
  String get batchColAlerts => '预警';

  @override
  String get compareTitle => '分子比较';

  @override
  String get compareSubtitle => '并排比较两个分子';

  @override
  String get compareMol1Label => '分子1';

  @override
  String get compareMol1Hint => '分子1的SMILES';

  @override
  String get compareMol2Label => '分子2';

  @override
  String get compareMol2Hint => '分子2的SMILES';

  @override
  String get compareButton => '比较';

  @override
  String get compareTanimoto => 'Tanimoto相似度: ';

  @override
  String get compareColProperty => '性质';

  @override
  String get compareColMol1 => '分子1';

  @override
  String get compareColDelta => '差值';

  @override
  String get compareColMol2 => '分子2';

  @override
  String get searchTitle => 'PubChem搜索';

  @override
  String get searchSubtitle => '按化合物名称搜索PubChem并获取SMILES';

  @override
  String get searchHint => '例：aspirin, caffeine, ibuprofen, glucose...';

  @override
  String get searchButton => '搜索PubChem';

  @override
  String searchFoundResults(int count) {
    return '找到 $count 个结果';
  }

  @override
  String get searchQuickSearch => '快速搜索';

  @override
  String get searchPredictButton => '预测性质';

  @override
  String get optimizeTitle => 'SELFIES遗传算法';

  @override
  String get optimizeSeedLabel => '种子分子（SMILES，每行一个）';

  @override
  String get optimizeShowSeedProps => '显示种子分子性质';

  @override
  String get optimizePopSize => '种群大小';

  @override
  String get optimizeGenerations => '进化代数';

  @override
  String get optimizeObjectives => '优化目标';

  @override
  String get optimizeAdd => '添加';

  @override
  String get optimizeStart => '开始优化';

  @override
  String get optimizeSubmitting => '提交中…';

  @override
  String get optimizeRunning => '运行中…';

  @override
  String get optimizeEvolving => '分子进化中…';

  @override
  String optimizeCandidates(int count) {
    return '$count 个候选分子';
  }

  @override
  String get optimizeCopySelfies => '复制SELFIES';

  @override
  String get optimizePending => '等待中…';

  @override
  String get optimizeDone => '完成';

  @override
  String optimizeFoundCandidates(int count) {
    return '找到 $count 个候选分子';
  }

  @override
  String get optimizeError => '错误';

  @override
  String get optimizeSetParams => '设置参数并开始优化';

  @override
  String get optimizeSelfiesDesc => '通过遗传算法进化SELFIES字符串';

  @override
  String optimizeJobLabel(String id) {
    return '任务: $id';
  }

  @override
  String get cardMolDescriptors => '分子描述符';

  @override
  String get cardDrugLikeness => '类药性';

  @override
  String get cardMlPredictions => 'ML模型预测';

  @override
  String get cardStructuralAlerts => '结构预警';

  @override
  String cardDrugLike(int n) {
    return '类药性 ($n 项违规)';
  }

  @override
  String cardNotDrugLike(int n) {
    return '非类药性 ($n 项违规)';
  }

  @override
  String get cardNoAlerts => '无结构预警';

  @override
  String cardAlertsFound(int n) {
    return '发现 $n 项预警';
  }

  @override
  String get cardPainsLabel => 'PAINS:';

  @override
  String get cardBrenkLabel => 'Brenk:';

  @override
  String get cardSolubility => '水溶性';

  @override
  String get cardBbbp => '血脑屏障透过性';

  @override
  String get cardBace => 'BACE-1抑制';

  @override
  String get cardHiv => 'HIV活性';

  @override
  String get cardTox21 => 'Tox21毒性终点';

  @override
  String get cardClinTox => '临床毒性';

  @override
  String get cardSider => 'SIDER副作用';

  @override
  String get cardMuv => 'MUV生物活性';

  @override
  String get cardFreesolv => '水化自由能';

  @override
  String get cardLipo => '亲脂性 (logD)';

  @override
  String get commonCopy => '复制';

  @override
  String get commonScore => '评分';

  @override
  String commonWeightLabel(String w) {
    return '权重: $w';
  }

  @override
  String get commonTarget => '目标值';

  @override
  String get commonNoMolecule => '无分子';

  @override
  String get commonFormula => '分子式: ';

  @override
  String get commonPubchemCid => 'PubChem CID: ';
}
