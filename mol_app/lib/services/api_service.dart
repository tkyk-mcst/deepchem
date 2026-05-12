import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class ApiService {
  static final _base = AppConfig.apiBaseUrl;

  static Future<PredictionResult> predict(String smiles) async {
    final res = await http.post(
      Uri.parse('$_base/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'smiles': smiles}),
    );
    if (res.statusCode == 200) {
      return PredictionResult.fromJson(jsonDecode(res.body));
    }
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<List<PredictionResult>> predictBatch(List<String> smilesList) async {
    final res = await http.post(
      Uri.parse('$_base/predict/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'smiles_list': smilesList}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((e) => PredictionResult.fromJson(e))
          .toList();
    }
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static String imageUrl(String smiles, {int w = 300, int h = 200}) {
    final encoded = Uri.encodeComponent(smiles);
    return '$_base/molecule/image?smiles=$encoded&width=$w&height=$h';
  }

  static Future<Map<String, dynamic>> standardize(String smiles) async {
    final encoded = Uri.encodeComponent(smiles);
    final res = await http.get(Uri.parse('$_base/molecule/standardize?smiles=$encoded'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<Map<String, dynamic>> similarity(String s1, String s2) async {
    final e1 = Uri.encodeComponent(s1);
    final e2 = Uri.encodeComponent(s2);
    final res = await http.get(Uri.parse('$_base/molecule/similarity?smiles1=$e1&smiles2=$e2'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<Map<String, dynamic>> compare(String s1, String s2) async {
    final res = await http.post(
      Uri.parse('$_base/molecule/compare'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'smiles1': s1, 'smiles2': s2}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<List<SampleMolecule>> getSamples() async {
    final res = await http.get(Uri.parse('$_base/samples'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['molecules'] as List)
          .map((e) => SampleMolecule.fromJson(e))
          .toList();
    }
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<List<PubChemResult>> pubchemSearch(String name) async {
    final encoded = Uri.encodeComponent(name);
    final res = await http.get(Uri.parse('$_base/pubchem/search?name=$encoded'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((e) => PubChemResult.fromJson(e))
          .toList();
    }
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<Map<String, dynamic>> getAlerts(String smiles) async {
    final encoded = Uri.encodeComponent(smiles);
    final res = await http.get(Uri.parse('$_base/molecule/alerts?smiles=$encoded'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<List<Map<String, dynamic>>> getVariants(String smiles) async {
    final encoded = Uri.encodeComponent(smiles);
    final res = await http.get(Uri.parse('$_base/molecule/variants?smiles=$encoded'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['variants']);
    }
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    final res = await http.get(Uri.parse('$_base/health'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, 'Server unreachable');
  }

  static Future<Map<String, dynamic>> submitOptimize({
    required List<String> seeds,
    required Map<String, dynamic> objectives,
    int popSize = 40,
    int nGenerations = 20,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/optimize/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'seeds': seeds,
        'objectives': objectives,
        'pop_size': popSize,
        'n_generations': nGenerations,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<Map<String, dynamic>> getJob(String jobId) async {
    final res = await http.get(Uri.parse('$_base/jobs/$jobId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, _errorMsg(res));
  }

  static Future<List<Map<String, dynamic>>> predictBatchForGA(
      List<String> smilesList) async {
    final res = await http.post(
      Uri.parse('$_base/predict/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'smiles_list': smilesList}),
    );
    if (res.statusCode != 200) throw ApiException(res.statusCode, _errorMsg(res));
    final data = jsonDecode(res.body);
    return (data['results'] as List).map<Map<String, dynamic>>((e) {
      final m = e as Map<String, dynamic>;
      final d = (m['descriptors'] as Map<String, dynamic>?) ?? {};
      final dl = (m['drug_likeness'] as Map<String, dynamic>?) ?? {};
      final preds = (m['predictions'] as Map<String, dynamic>?) ?? {};
      final bbbp = (preds['bbbp'] as Map<String, dynamic>?) ?? {};
      final sol = (preds['solubility'] as Map<String, dynamic>?) ?? {};
      return {
        'smiles': m['smiles'],
        'valid': m['valid'] ?? false,
        'mw': d['molecular_weight'],
        'logP': d['logp'],
        'tpsa': d['tpsa'],
        'hbd': d['hbd'],
        'hba': d['hba'],
        'qed': dl['qed'],
        'bbbp': bbbp['probability'],
        'logS': sol['logS'],
      };
    }).toList();
  }

  static String _errorMsg(http.Response res) {
    try {
      return jsonDecode(res.body)['detail'] ?? 'Error ${res.statusCode}';
    } catch (_) {
      return 'Error ${res.statusCode}';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
