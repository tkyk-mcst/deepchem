import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/molecule_image.dart';
import '../widgets/admet_radar.dart';
import '../widgets/property_cards.dart';

class PredictScreen extends StatefulWidget {
  final String? initialSmiles;

  const PredictScreen({super.key, this.initialSmiles});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _ctrl = TextEditingController();
  PredictionResult? _result;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSmiles != null) {
      _ctrl.text = widget.initialSmiles!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _predict());
    }
  }

  @override
  void didUpdateWidget(PredictScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialSmiles != old.initialSmiles &&
        widget.initialSmiles != null) {
      _ctrl.text = widget.initialSmiles!;
      _predict();
    }
  }

  Future<void> _predict() async {
    final smiles = _ctrl.text.trim();
    if (smiles.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _variants = [];
    });
    try {
      final result = await ApiService.predict(smiles);
      setState(() {
        _result = result;
        _loading = false;
      });
      // load variants in background
      _loadVariants(smiles);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadVariants(String smiles) async {
    try {
      final v = await ApiService.getVariants(smiles);
      if (mounted) setState(() => _variants = v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Single Molecule Prediction',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Enter a SMILES string to get the full ADMET profile.',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          _buildInputRow(),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Card(
              color: Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),
            ),
          if (_result != null) _buildResults(_result!),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'SMILES string (e.g. CC(=O)Oc1ccccc1C(=O)O)',
              prefixIcon: const Icon(Icons.science_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _result = null;
                          _error = null;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _predict(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Predict'),
          onPressed: _loading ? null : _predict,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(PredictionResult r) {
    final radarData = r.radarValues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: image + radar
        LayoutBuilder(builder: (ctx, constraints) {
          final wide = constraints.maxWidth > 700;
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMolCard(r),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRadarCard(radarData)),
                  ],
                )
              : Column(children: [
                  _buildMolCard(r),
                  const SizedBox(height: 16),
                  _buildRadarCard(radarData),
                ]);
        }),
        const SizedBox(height: 16),
        // Lipinski
        if (r.drugLikeness != null)
          LipinskiCard(drugLikeness: r.drugLikeness!),
        const SizedBox(height: 16),
        // Descriptors
        if (r.descriptors != null)
          DescriptorCard(descriptors: r.descriptors!),
        const SizedBox(height: 16),
        // Alerts
        if (r.alerts != null) AlertsCard(alerts: r.alerts!),
        const SizedBox(height: 16),
        // ML predictions
        if (r.predictions != null && r.predictions!.isNotEmpty)
          PredictionsCard(predictions: r.predictions!),
        // Variants
        if (_variants.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildVariantsCard(),
        ],
      ],
    );
  }

  Widget _buildMolCard(PredictionResult r) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            MoleculeImage(smiles: r.smiles, width: 280, height: 200),
            const SizedBox(height: 8),
            SelectableText(
              r.canonicalSmiles ?? r.smiles,
              style: const TextStyle(
                  fontSize: 11, fontFamily: 'monospace', color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarCard(Map<String, double> radarData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: radarData.isNotEmpty
            ? AdmetRadarChart(values: radarData)
            : const Center(child: Text('No model predictions available')),
      ),
    );
  }

  Widget _buildVariantsCard() {
    return InfoCard(
      title: 'Analog Suggestions',
      child: Column(
        children: [
          const Text('Click an analog to predict it',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _variants.map((v) {
              return ActionChip(
                avatar: const Icon(Icons.science, size: 14),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['modification'] ?? '',
                        style: const TextStyle(fontSize: 10)),
                    Text(
                      (v['smiles'] as String).length > 25
                          ? '${(v['smiles'] as String).substring(0, 25)}…'
                          : v['smiles'] as String,
                      style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: Colors.white54),
                    ),
                  ],
                ),
                onPressed: () {
                  _ctrl.text = v['smiles'] as String;
                  _predict();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
