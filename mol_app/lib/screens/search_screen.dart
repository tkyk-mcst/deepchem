import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/molecule_image.dart';
import '../l10n/l10n.dart';

class SearchScreen extends StatefulWidget {
  final void Function(String smiles) onPredict;

  const SearchScreen({super.key, required this.onPredict});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<PubChemResult> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await ApiService.pubchemSearch(name);
      setState(() {
        _results = results;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.statusCode == 404
            ? '"$name" not found in PubChem'
            : e.message;
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
          Text(context.l10n.searchTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(context.l10n.searchSubtitle,
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text(_error!,
                        style:
                            const TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
          if (_results.isNotEmpty) _buildResults(),
          const SizedBox(height: 32),
          _buildQuickSearch(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: context.l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          icon: const Icon(Icons.search),
          label: Text(context.l10n.searchButton),
          onPressed: _loading ? null : _search,
          style: FilledButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.searchFoundResults(_results.length),
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        ..._results.map((r) => _ResultCard(
              result: r,
              onPredict: widget.onPredict,
            )),
      ],
    );
  }

  Widget _buildQuickSearch() {
    final suggestions = [
      'aspirin', 'caffeine', 'ibuprofen', 'paracetamol', 'morphine',
      'dopamine', 'serotonin', 'glucose', 'cholesterol', 'testosterone',
      'penicillin', 'metformin', 'atorvastatin', 'omeprazole',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.searchQuickSearch,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((s) => ActionChip(
                    label: Text(s),
                    onPressed: () {
                      _ctrl.text = s;
                      _search();
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PubChemResult result;
  final void Function(String) onPredict;

  const _ResultCard({required this.result, required this.onPredict});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Molecule image
            if (result.smiles.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MoleculeImage(
                    smiles: result.smiles, width: 140, height: 100),
              ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.iupac.isNotEmpty)
                    Text(result.iupac,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  if (result.formula.isNotEmpty)
                    Row(
                      children: [
                        Text(context.l10n.commonFormula,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text(result.formula,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Text('MW: ',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text('${result.mw}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  if (result.cid != null) ...[
                    const SizedBox(height: 4),
                    Text('${context.l10n.commonPubchemCid}${result.cid}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                  const SizedBox(height: 8),
                  SelectableText(
                    result.smiles,
                    style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.tealAccent),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(context.l10n.searchPredictButton),
                    onPressed: () => onPredict(result.smiles),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
