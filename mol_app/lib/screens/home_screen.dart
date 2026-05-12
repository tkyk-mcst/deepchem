import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String smiles) onPredict;

  const HomeScreen({super.key, required this.onPredict});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SampleMolecule> _samples = [];
  Map<String, dynamic>? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.getSamples(),
        ApiService.checkHealth(),
      ]);
      setState(() {
        _samples = results[0] as List<SampleMolecule>;
        _health = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(context),
          const SizedBox(height: 32),
          if (_health != null) _buildStatus(),
          const SizedBox(height: 32),
          _buildFeatureGrid(context),
          const SizedBox(height: 32),
          Text('Sample Molecules',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            _buildSampleGrid(),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade900, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: Colors.tealAccent, size: 36),
              const SizedBox(width: 12),
              Text(
                'DeepChem',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Comprehensive molecular property prediction powered by DeepChem & RDKit.\n'
            'Predict solubility, BBB permeability, toxicity, drug-likeness and more.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          _QuickPredictBar(onPredict: widget.onPredict),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final models = List<String>.from(_health!['models_loaded'] ?? []);
    return Card(
      color: Colors.green.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.greenAccent, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
            const SizedBox(width: 8),
            const Text('API Online  |  Models: ',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            Expanded(
              child: Text(
                models.join(', '),
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      (Icons.biotech, 'Single Predict', 'Full ADMET profile + radar chart', Colors.tealAccent),
      (Icons.table_chart, 'Batch Predict', 'Upload CSV, predict hundreds of molecules', Colors.blueAccent),
      (Icons.compare, 'Compare', 'Side-by-side molecule comparison', Colors.purpleAccent),
      (Icons.search, 'PubChem Search', 'Find molecules by name', Colors.amberAccent),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: features.map((f) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f.$1, color: f.$4, size: 28),
                  const SizedBox(height: 8),
                  Text(f.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(f.$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSampleGrid() {
    final categoryColors = {
      'NSAID': Colors.redAccent,
      'Stimulant': Colors.amberAccent,
      'Analgesic': Colors.orangeAccent,
      'Antibiotic': Colors.greenAccent,
      'Neurotransmitter': Colors.blueAccent,
      'Lipid': Colors.purpleAccent,
      'Antidiabetic': Colors.cyanAccent,
      'Antiviral': Colors.tealAccent,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _samples.length,
      itemBuilder: (_, i) {
        final m = _samples[i];
        final color = categoryColors[m.category] ?? Colors.white54;
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget.onPredict(m.smiles),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(m.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      if (m.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Text(m.category!,
                              style: TextStyle(fontSize: 9, color: color)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(m.description,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white60)),
                  const Spacer(),
                  Text(
                    m.smiles.length > 30
                        ? '${m.smiles.substring(0, 30)}…'
                        : m.smiles,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickPredictBar extends StatefulWidget {
  final void Function(String smiles) onPredict;
  const _QuickPredictBar({required this.onPredict});

  @override
  State<_QuickPredictBar> createState() => _QuickPredictBarState();
}

class _QuickPredictBarState extends State<_QuickPredictBar> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Enter SMILES (e.g. CC(=O)Oc1ccccc1C(=O)O)',
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) widget.onPredict(v.trim());
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Predict'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onPressed: () {
            if (_ctrl.text.trim().isNotEmpty) {
              widget.onPredict(_ctrl.text.trim());
            }
          },
        ),
      ],
    );
  }
}
