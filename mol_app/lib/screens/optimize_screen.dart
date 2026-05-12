import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// ── Job data model ─────────────────────────────────────────────────────────────

class _Job {
  final String id;
  final List<String> seeds;
  final List<String> objectiveKeys;
  String status;
  Map<String, dynamic>? result;
  String? error;

  _Job({
    required this.id,
    required this.seeds,
    required this.objectiveKeys,
    required this.status,
    this.result,
    this.error,
  });

  bool get isActive => status == 'pending' || status == 'running';
  bool get isDone   => status == 'done';
  bool get isError  => status == 'error';

  Color get statusColor {
    switch (status) {
      case 'done':    return const Color(0xFF4ADE80);
      case 'error':   return const Color(0xFFF87171);
      case 'running': return Colors.tealAccent;
      default:        return Colors.white38;
    }
  }
}

// ── Main screen ────────────────────────────────────────────────────────────────

class OptimizeScreen extends StatefulWidget {
  const OptimizeScreen({super.key});

  @override
  State<OptimizeScreen> createState() => _OptimizeScreenState();
}

class _OptimizeScreenState extends State<OptimizeScreen> {
  final _seedCtrl = TextEditingController(text: 'CC(=O)Oc1ccccc1C(=O)O');
  int _popSize = 40;
  int _nGen = 20;
  bool _submitting = false;
  String? _submitError;

  List<Map<String, dynamic>> _seedProps = [];
  bool _seedLoading = false;

  _Job? _currentJob;
  Timer? _pollTimer;

  final List<_ObjRow> _objectives = [
    _ObjRow(property: 'qed',      mode: 'maximize', weight: 1.0),
    _ObjRow(property: 'sa_score', mode: 'minimize', weight: 0.5),
  ];

  static const _availableProps = [
    'qed', 'sa_score', 'logP', 'tpsa', 'mw', 'hbd', 'hba', 'bbbp', 'logS',
  ];

  @override
  void dispose() {
    _pollTimer?.cancel();
    _seedCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildObjectives() {
    final m = <String, dynamic>{};
    for (final obj in _objectives) {
      final cfg = <String, dynamic>{'mode': obj.mode, 'weight': obj.weight};
      if (obj.mode == 'target' && obj.target != null) cfg['target'] = obj.target;
      m[obj.property] = cfg;
    }
    return m;
  }

  Future<void> _fetchSeedProps() async {
    final seeds = _seedCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (seeds.isEmpty) return;
    setState(() => _seedLoading = true);
    try {
      final resp = await ApiService.predictBatchForGA(seeds);
      setState(() { _seedProps = resp; _seedLoading = false; });
    } catch (_) {
      setState(() => _seedLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_currentJob?.isActive == true) return;
    final seeds = _seedCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (seeds.isEmpty) return;
    setState(() { _submitting = true; _submitError = null; });
    try {
      final resp = await ApiService.submitOptimize(
        seeds: seeds,
        objectives: _buildObjectives(),
        popSize: _popSize,
        nGenerations: _nGen,
      );
      final jobId = resp['job_id'] as String;
      setState(() {
        _currentJob = _Job(
          id: jobId,
          seeds: seeds.take(3).toList(),
          objectiveKeys: _objectives.map((o) => o.property).toList(),
          status: 'pending',
        );
        _submitting = false;
      });
      _startPolling();
    } catch (e) {
      setState(() {
        _submitError = e.toString().replaceFirst('ApiException(\\d+): ', '');
        _submitting = false;
      });
    }
  }

  void _startPolling() {
    if (_pollTimer?.isActive ?? false) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    final job = _currentJob;
    if (job == null || !job.isActive) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    try {
      final data = await ApiService.getJob(job.id);
      final status = data['status'] as String? ?? 'error';
      if (mounted) setState(() {
        job.status = status;
        if (status == 'done') {
          job.result = data;
          job.error = null;
        } else if (status == 'error') {
          job.error = data['error'] as String? ?? 'Unknown error';
        }
      });
    } catch (_) {}
    if (!(_currentJob?.isActive ?? false)) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = _submitting || (_currentJob?.isActive == true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELFIES Genetic Algorithm', style: TextStyle(fontSize: 16)),
      ),
      body: Row(
        children: [
          // ── Config panel ─────────────────────────────────────────────────
          SizedBox(
            width: 340,
            child: Container(
              color: const Color(0xFF12122A),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Seed molecules (SMILES, one per line)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _seedCtrl,
                      maxLines: 4,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                      decoration: _inputDeco('SMILES…'),
                      onChanged: (_) => setState(() => _seedProps = []),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _seedLoading ? null : _fetchSeedProps,
                      icon: _seedLoading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.info_outline, size: 16),
                      label: const Text('Show seed properties',
                          style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.tealAccent,
                          padding: EdgeInsets.zero),
                    ),
                    if (_seedProps.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...List.generate(_seedProps.length, (i) {
                        final p = _seedProps[i];
                        if (p['valid'] != true) return const SizedBox.shrink();
                        final smiles = p['smiles'] as String? ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                smiles.length > 36
                                    ? '${smiles.substring(0, 34)}…'
                                    : smiles,
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  ApiService.imageUrl(smiles, w: 280, h: 160),
                                  width: 280,
                                  height: 160,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6, runSpacing: 4,
                                children: _objectives.map((obj) {
                                  final val = p[obj.property];
                                  if (val == null) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.tealAccent.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '${obj.property}: $val',
                                      style: const TextStyle(
                                          color: Colors.tealAccent, fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'MW: ${p['mw']}  QED: ${p['qed']}  '
                                'logP: ${p['logP']}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Pop. size'),
                          const SizedBox(height: 4),
                          _NumberField(
                              value: _popSize, min: 10, max: 200,
                              onChanged: (v) => setState(() => _popSize = v)),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Generations'),
                          const SizedBox(height: 4),
                          _NumberField(
                              value: _nGen, min: 5, max: 100,
                              onChanged: (v) => setState(() => _nGen = v)),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _Label('Objectives'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() => _objectives.add(
                            _ObjRow(property: 'logP', mode: 'maximize', weight: 1.0))),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(foregroundColor: Colors.tealAccent),
                      ),
                    ]),
                    ..._objectives.asMap().entries.map((e) => _ObjRowWidget(
                      key: ValueKey(e.key),
                      row: e.value,
                      availableProps: _availableProps,
                      onDelete: () => setState(() => _objectives.removeAt(e.key)),
                      onChanged: () => setState(() {}),
                    )),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: running ? null : _submit,
                        icon: running
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.play_arrow),
                        label: Text(
                          _submitting
                              ? 'Submitting…'
                              : running
                                  ? 'Running…'
                                  : 'Start Optimization',
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF87171).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFF87171).withValues(alpha: 0.4)),
                        ),
                        child: Text(_submitError!,
                            style: const TextStyle(
                                color: Color(0xFFF87171), fontSize: 13)),
                      ),
                    ],
                    if (_currentJob != null) ...[
                      const SizedBox(height: 16),
                      _StatusBadge(job: _currentJob!),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Results panel ────────────────────────────────────────────────
          Expanded(
            child: _currentJob == null
                ? const _EmptyPlaceholder()
                : _JobResults(job: _currentJob!),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF0F0F1A),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.tealAccent)),
  );
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _Job job;
  const _StatusBadge({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: job.statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: job.statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        if (job.isActive)
          const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent))
        else
          Icon(
              job.isDone ? Icons.check_circle_outline : Icons.error_outline,
              size: 16, color: job.statusColor),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_label(job.status),
              style: TextStyle(
                  color: job.statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (job.isDone)
            Text('${job.result?['n_results'] ?? 0} candidates found',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          if (job.isError && job.error != null)
            Text(job.error!,
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 11)),
        ])),
      ]),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'pending': return 'Pending…';
      case 'running': return 'Running…';
      case 'done':    return 'Done';
      case 'error':   return 'Error';
      default:        return s;
    }
  }
}

// ── Empty placeholder ──────────────────────────────────────────────────────────

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.white24),
      SizedBox(height: 14),
      Text('Set parameters and start optimization',
          style: TextStyle(color: Colors.white60, fontSize: 16)),
      SizedBox(height: 6),
      Text('SELFIES strings evolved via genetic algorithm',
          style: TextStyle(color: Colors.white38, fontSize: 13)),
    ]),
  );
}

// ── Results panel ──────────────────────────────────────────────────────────────

class _JobResults extends StatelessWidget {
  final _Job job;
  const _JobResults({required this.job});

  @override
  Widget build(BuildContext context) {
    if (job.isActive) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Colors.tealAccent)),
          const SizedBox(height: 18),
          const Text('Evolving molecules…',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Job: ${job.id}',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12, fontFamily: 'monospace')),
        ]),
      );
    }

    if (job.isError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF87171).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 36),
            const SizedBox(height: 12),
            Text(job.error ?? 'Unknown error',
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 14)),
          ]),
        ),
      );
    }

    final results =
        (job.result?['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
            ),
            child: const Text('GA',
                style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Text('${results.length} candidates',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ResultCard(
            rank: i + 1,
            data: results[i],
            objectiveKeys: job.objectiveKeys,
          ),
        ),
      ),
    ]);
  }
}

// ── Result card ────────────────────────────────────────────────────────────────

class _ResultCard extends StatefulWidget {
  final int rank;
  final Map<String, dynamic> data;
  final List<String> objectiveKeys;
  const _ResultCard(
      {required this.rank, required this.data, required this.objectiveKeys});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _expanded = false;

  static const _chipColors = [
    Color(0xFF4ADE80),
    Colors.tealAccent,
    Color(0xFFFBBF24),
    Color(0xFFC084FC),
    Color(0xFFF472B6),
  ];

  @override
  Widget build(BuildContext context) {
    final selfies = widget.data['selfies'] as String? ?? '';
    final smiles  = widget.data['smiles']  as String? ?? '';
    final score   = widget.data['score'];
    final props   = widget.data['properties'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${widget.rank}',
                        style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    smiles.length > 55 ? '${smiles.substring(0, 53)}…' : smiles,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
                if (score != null) ...[
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('score',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                    Text(
                      score is num ? score.toStringAsFixed(3) : '$score',
                      style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  ]),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.white54,
                  onPressed: () => Clipboard.setData(ClipboardData(text: selfies)),
                  tooltip: 'Copy SELFIES',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54, size: 20),
              ]),
              if (widget.objectiveKeys.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: widget.objectiveKeys.asMap().entries.map((e) {
                    final color = _chipColors[e.key % _chipColors.length];
                    final val = props[e.value];
                    if (val == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: '${e.value}  ',
                              style: TextStyle(
                                  color: color.withValues(alpha: 0.8), fontSize: 12)),
                          TextSpan(
                              text: '$val',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (smiles.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.white,
                      width: 200, height: 150,
                      child: Image.network(
                        ApiService.imageUrl(smiles, w: 200, h: 150),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CopyRow('SELFIES', selfies),
                    const SizedBox(height: 10),
                    _CopyRow('SMILES', smiles),
                  ],
                )),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: [
                  'qed', 'sa_score', 'logP', 'tpsa', 'mw',
                  'hbd', 'hba', 'bbbp', 'logS',
                ].map((k) => SizedBox(
                    width: 130,
                    child: _PropCard(label: k, value: '${props[k] ?? '-'}'))).toList(),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _PropCard extends StatelessWidget {
  final String label;
  final String value;
  const _PropCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252540),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 2),
      Row(children: [
        Expanded(
          child: Text(
            value.length > 80 ? '${value.substring(0, 78)}…' : value,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 13),
          color: Colors.white38,
          onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ]),
    ]);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 13));
}

class _NumberField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _NumberField(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$value',
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: (s) {
        final v = int.tryParse(s);
        if (v != null) onChanged(v.clamp(min, max));
      },
    );
  }
}

class _ObjRow {
  String property;
  String mode;
  double weight;
  double? target;
  _ObjRow(
      {required this.property,
      required this.mode,
      required this.weight,
      this.target});
}

class _ObjRowWidget extends StatefulWidget {
  final _ObjRow row;
  final List<String> availableProps;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _ObjRowWidget(
      {super.key,
      required this.row,
      required this.availableProps,
      required this.onDelete,
      required this.onChanged});

  @override
  State<_ObjRowWidget> createState() => _ObjRowWidgetState();
}

class _ObjRowWidgetState extends State<_ObjRowWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
              flex: 3,
              child: DropdownButton<String>(
                value: widget.row.property,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E32),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                underline: const SizedBox(),
                items: widget.availableProps
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => widget.row.property = v);
                    widget.onChanged();
                  }
                },
              )),
          const SizedBox(width: 8),
          Expanded(
              flex: 3,
              child: DropdownButton<String>(
                value: widget.row.mode,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E32),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                underline: const SizedBox(),
                items: ['maximize', 'minimize', 'target']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => widget.row.mode = v);
                    widget.onChanged();
                  }
                },
              )),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Colors.white54),
            onPressed: widget.onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ]),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Weight: ${widget.row.weight.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Slider(
                value: widget.row.weight,
                min: 0.1, max: 2.0, divisions: 19,
                activeColor: Colors.tealAccent,
                inactiveColor: Colors.white12,
                onChanged: (v) {
                  setState(() => widget.row.weight = v);
                  widget.onChanged();
                },
              ),
            ]),
          ),
          if (widget.row.mode == 'target') ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: '${widget.row.target ?? 2.5}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target',
                  labelStyle:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF1E1E32),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.white12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                onChanged: (s) {
                  final v = double.tryParse(s);
                  if (v != null) {
                    widget.row.target = v;
                    widget.onChanged();
                  }
                },
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}
