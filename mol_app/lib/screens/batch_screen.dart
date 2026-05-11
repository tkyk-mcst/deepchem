import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/molecule_image.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final _ctrl = TextEditingController();
  List<PredictionResult> _results = [];
  bool _loading = false;
  String? _error;
  int _progress = 0;
  int _total = 0;
  String _sortBy = 'smiles';
  bool _sortAsc = true;

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null) return;
    try {
      final bytes = result.files.first.bytes;
      if (bytes == null) return;
      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter().convert(content);
      final smilesList = <String>[];
      for (final row in rows) {
        if (row.isEmpty) continue;
        final cell = row.first.toString().trim();
        if (cell.toLowerCase() == 'smiles') continue;
        if (cell.isNotEmpty) smilesList.add(cell);
      }
      setState(() => _ctrl.text = smilesList.join('\n'));
    } catch (e) {
      setState(() => _error = 'CSV parse error: $e');
    }
  }

  Future<void> _runBatch() async {
    final lines = _ctrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _total = lines.length;
      _progress = 0;
    });

    try {
      final allResults = <PredictionResult>[];
      for (var i = 0; i < lines.length; i += 20) {
        final chunk = lines.sublist(i, (i + 20).clamp(0, lines.length));
        final res = await ApiService.predictBatch(chunk);
        allResults.addAll(res);
        if (mounted) setState(() => _progress = allResults.length);
      }
      setState(() {
        _results = allResults;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  List<PredictionResult> get _sortedResults {
    final sorted = List<PredictionResult>.from(_results);
    sorted.sort((a, b) {
      dynamic va, vb;
      switch (_sortBy) {
        case 'mw':
          va = a.descriptors?['molecular_weight'] ?? 0;
          vb = b.descriptors?['molecular_weight'] ?? 0;
        case 'logp':
          va = a.descriptors?['logp'] ?? 0;
          vb = b.descriptors?['logp'] ?? 0;
        case 'qed':
          va = a.drugLikeness?['qed'] ?? 0;
          vb = b.drugLikeness?['qed'] ?? 0;
        case 'solubility':
          va = a.predictions?['solubility']?['logS'] ?? -10;
          vb = b.predictions?['solubility']?['logS'] ?? -10;
        default:
          va = a.smiles;
          vb = b.smiles;
      }
      int cmp;
      if (va is num && vb is num) {
        cmp = va.compareTo(vb);
      } else {
        cmp = va.toString().compareTo(vb.toString());
      }
      return _sortAsc ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Batch Prediction',
              style: Theme.of(context).textTheme.headlineSmall),
          const Text('Upload CSV or paste SMILES (one per line)',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload CSV'),
                onPressed: _pickCsv,
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text(_loading ? 'Running...' : 'Run Batch'),
                onPressed: _loading ? null : _runBatch,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'CCO\nCC(=O)Oc1ccccc1C(=O)O\nCn1c(=O)c2c(ncn2C)n(c1=O)C\n...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading) ...[
            LinearProgressIndicator(
                value: _total > 0 ? _progress / _total : null),
            const SizedBox(height: 6),
            Text('Processing $_progress / $_total molecules...',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${_results.length} results',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                const Text('Sort: ',
                    style: TextStyle(fontSize: 13, color: Colors.white54)),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'smiles', child: Text('SMILES')),
                    DropdownMenuItem(value: 'mw', child: Text('MW')),
                    DropdownMenuItem(value: 'logp', child: Text('LogP')),
                    DropdownMenuItem(value: 'qed', child: Text('QED')),
                    DropdownMenuItem(
                        value: 'solubility', child: Text('Solubility')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v!),
                ),
                IconButton(
                  icon: Icon(_sortAsc
                      ? Icons.arrow_upward
                      : Icons.arrow_downward),
                  onPressed: () => setState(() => _sortAsc = !_sortAsc),
                  iconSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildTable()),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    final sorted = _sortedResults;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 40,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 80,
            columns: const [
              DataColumn(label: Text('Structure')),
              DataColumn(label: Text('SMILES')),
              DataColumn(label: Text('MW'), numeric: true),
              DataColumn(label: Text('LogP'), numeric: true),
              DataColumn(label: Text('QED'), numeric: true),
              DataColumn(label: Text('logS'), numeric: true),
              DataColumn(label: Text('BBB%'), numeric: true),
              DataColumn(label: Text('Drug-Like')),
              DataColumn(label: Text('Alerts')),
            ],
            rows: sorted.map((r) {
              final d = r.descriptors ?? {};
              final dl = r.drugLikeness ?? {};
              final p = r.predictions ?? {};
              final sol = p['solubility'];
              final bbbp = p['bbbp'];
              final hasAlerts = r.alerts?['has_alerts'] == true;
              final drugLike = dl['drug_like'] == true;
              return DataRow(cells: [
                DataCell(
                  r.valid
                      ? MoleculeImage(
                          smiles: r.smiles, width: 80, height: 60)
                      : const Icon(Icons.error_outline,
                          color: Colors.redAccent),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      r.smiles.length > 22
                          ? '${r.smiles.substring(0, 22)}…'
                          : r.smiles,
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                DataCell(Text('${d['molecular_weight'] ?? '-'}')),
                DataCell(Text('${d['logp'] ?? '-'}')),
                DataCell(Text('${dl['qed'] ?? '-'}')),
                DataCell(
                    Text(sol != null ? '${sol['logS']}' : '-')),
                DataCell(Text(bbbp != null
                    ? '${((bbbp['probability'] as num) * 100).toStringAsFixed(0)}%'
                    : '-')),
                DataCell(Icon(
                  drugLike ? Icons.check_circle : Icons.cancel,
                  color:
                      drugLike ? Colors.greenAccent : Colors.redAccent,
                  size: 18,
                )),
                DataCell(Icon(
                  hasAlerts
                      ? Icons.warning_amber
                      : Icons.verified_outlined,
                  color: hasAlerts
                      ? Colors.orangeAccent
                      : Colors.greenAccent,
                  size: 18,
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
