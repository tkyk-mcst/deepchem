import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/molecule_image.dart';
import '../widgets/admet_radar.dart';
import '../widgets/property_cards.dart';
import '../l10n/l10n.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  Map<String, dynamic>? _compareResult;
  bool _loading = false;
  String? _error;

  Future<void> _compare() async {
    final s1 = _ctrl1.text.trim();
    final s2 = _ctrl2.text.trim();
    if (s1.isEmpty || s2.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _compareResult = null;
    });
    try {
      final result = await ApiService.compare(s1, s2);
      setState(() {
        _compareResult = result;
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.compareTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(context.l10n.compareSubtitle,
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          _buildInputs(),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Card(
              color: Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          if (_compareResult != null) _buildComparison(_compareResult!),
        ],
      ),
    );
  }

  Widget _buildInputs() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.compareMol1Label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _ctrl1,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: context.l10n.compareMol1Hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) => _compare(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Icon(Icons.compare_arrows,
              color: Colors.white38, size: 28),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.compareMol2Label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _ctrl2,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: context.l10n.compareMol2Hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) => _compare(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          icon: const Icon(Icons.compare),
          label: Text(context.l10n.compareButton),
          onPressed: _loading ? null : _compare,
          style: FilledButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildComparison(Map<String, dynamic> data) {
    final m1 = PredictionResult.fromJson(data['molecule_1']);
    final m2 = PredictionResult.fromJson(data['molecule_2']);
    final sim = data['similarity'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Similarity badge
        if (sim != null) _buildSimilarityBadge(sim),
        const SizedBox(height: 20),
        // Images side by side
        Row(
          children: [
            Expanded(child: _buildMolCard('Molecule 1', m1)),
            const SizedBox(width: 12),
            Expanded(child: _buildMolCard('Molecule 2', m2)),
          ],
        ),
        const SizedBox(height: 16),
        // Radar comparison
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AdmetRadarChart(values: m1.radarValues),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AdmetRadarChart(values: m2.radarValues),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Property diff table
        _buildDiffTable(m1, m2),
        const SizedBox(height: 16),
        // Drug-likeness
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m1.drugLikeness != null)
              Expanded(child: LipinskiCard(drugLikeness: m1.drugLikeness!)),
            const SizedBox(width: 12),
            if (m2.drugLikeness != null)
              Expanded(child: LipinskiCard(drugLikeness: m2.drugLikeness!)),
          ],
        ),
      ],
    );
  }

  Widget _buildSimilarityBadge(Map<String, dynamic> sim) {
    final score = (sim['tanimoto_similarity'] as num?)?.toDouble() ?? 0.0;
    final label = sim['interpretation'] ?? '';
    final color = score >= 0.7
        ? Colors.greenAccent
        : score >= 0.4
            ? Colors.amberAccent
            : Colors.redAccent;
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.compareTanimoto,
                style: const TextStyle(color: Colors.white70)),
            Text(
              score.toStringAsFixed(3),
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMolCard(String title, PredictionResult r) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            MoleculeImage(smiles: r.smiles, width: 250, height: 180),
            const SizedBox(height: 6),
            SelectableText(
              r.canonicalSmiles ?? r.smiles,
              style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffTable(PredictionResult m1, PredictionResult m2) {
    final d1 = m1.descriptors ?? {};
    final d2 = m2.descriptors ?? {};
    final rows = [
      ('MW (Da)', d1['molecular_weight'], d2['molecular_weight']),
      ('LogP', d1['logp'], d2['logp']),
      ('TPSA (Å²)', d1['tpsa'], d2['tpsa']),
      ('HBD', d1['hbd'], d2['hbd']),
      ('HBA', d1['hba'], d2['hba']),
      ('RotBonds', d1['rotatable_bonds'], d2['rotatable_bonds']),
      ('ArRings', d1['aromatic_rings'], d2['aromatic_rings']),
      ('Fsp3', d1['fsp3'], d2['fsp3']),
      ('Formula', d1['molecular_formula'], d2['molecular_formula']),
    ];

    return InfoCard(
      title: 'Property Comparison',
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white12))),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(context.l10n.compareColProperty,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 12)),
              ),
              Text(context.l10n.compareColMol1,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 12)),
              Text(context.l10n.compareColDelta,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 12)),
              Text(context.l10n.compareColMol2,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.purpleAccent, fontSize: 12)),
            ],
          ),
          ...rows.map((row) {
            final v1 = row.$2;
            final v2 = row.$3;
            Widget deltaWidget = const Text('-',
                style: TextStyle(color: Colors.white38, fontSize: 12));
            if (v1 is num && v2 is num) {
              final delta = v2 - v1;
              final color = delta == 0
                  ? Colors.white38
                  : delta > 0
                      ? Colors.greenAccent
                      : Colors.redAccent;
              deltaWidget = Text(
                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600),
              );
            }
            return TableRow(
              decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.white12, width: 0.3))),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(row.$1,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ),
                Text('$v1',
                    style: const TextStyle(fontSize: 13, color: Colors.blueAccent)),
                deltaWidget,
                Text('$v2',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.purpleAccent)),
              ],
            );
          }),
        ],
      ),
    );
  }
}
