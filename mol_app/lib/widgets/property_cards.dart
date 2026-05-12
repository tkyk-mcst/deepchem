import 'package:flutter/material.dart';

// ── Generic info card ────────────────────────────────────────────────────

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor ?? Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Descriptors grid ────────────────────────────────────────────────────

class DescriptorCard extends StatelessWidget {
  final Map<String, dynamic> descriptors;

  const DescriptorCard({super.key, required this.descriptors});

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('MW', descriptors['molecular_weight'], 'Da'),
      ('LogP', descriptors['logp'], ''),
      ('TPSA', descriptors['tpsa'], 'Å²'),
      ('HBD', descriptors['hbd'], ''),
      ('HBA', descriptors['hba'], ''),
      ('RotBonds', descriptors['rotatable_bonds'], ''),
      ('ArRings', descriptors['aromatic_rings'], ''),
      ('HeavyAtoms', descriptors['heavy_atoms'], ''),
      ('Rings', descriptors['rings'], ''),
      ('Fsp3', descriptors['fsp3'], ''),
      ('Formula', descriptors['molecular_formula'], ''),
    ];

    return InfoCard(
      title: 'Molecular Descriptors',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((e) => _DescBadge(e.$1, e.$2, e.$3)).toList(),
      ),
    );
  }
}

class _DescBadge extends StatelessWidget {
  final String label;
  final dynamic value;
  final String unit;

  const _DescBadge(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white54)),
          const SizedBox(height: 2),
          Text('$value${unit.isNotEmpty ? ' $unit' : ''}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Lipinski check ───────────────────────────────────────────────────────

class LipinskiCard extends StatelessWidget {
  final Map<String, dynamic> drugLikeness;

  const LipinskiCard({super.key, required this.drugLikeness});

  @override
  Widget build(BuildContext context) {
    final checks = [
      ('MW ≤ 500', drugLikeness['mw_ok']),
      ('LogP ≤ 5', drugLikeness['logp_ok']),
      ('HBD ≤ 5', drugLikeness['hbd_ok']),
      ('HBA ≤ 10', drugLikeness['hba_ok']),
      ('Veber Rules', drugLikeness['veber_ok']),
    ];
    final qed = drugLikeness['qed'];
    final violations = drugLikeness['violations'] ?? 0;
    final drugLike = drugLikeness['drug_like'] ?? false;

    return InfoCard(
      title: 'Drug-Likeness',
      borderColor: drugLike ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                drugLike ? Icons.check_circle : Icons.cancel,
                color: drugLike ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                drugLike ? 'Drug-Like ($violations violations)' : 'Not Drug-Like ($violations violations)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: drugLike ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
          if (qed != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('QED: ', style: TextStyle(color: Colors.white70)),
                Text('$qed', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: qed.toDouble(),
                    backgroundColor: Colors.white12,
                    color: _qedColor(qed.toDouble()),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: checks.map((c) {
              final ok = c.$2 as bool? ?? false;
              return Chip(
                label: Text(c.$1,
                    style: TextStyle(
                        fontSize: 11,
                        color: ok ? Colors.greenAccent : Colors.redAccent)),
                avatar: Icon(
                    ok ? Icons.check : Icons.close,
                    size: 14,
                    color: ok ? Colors.greenAccent : Colors.redAccent),
                backgroundColor: (ok ? Colors.green : Colors.red).withOpacity(0.1),
                side: BorderSide(
                    color: (ok ? Colors.greenAccent : Colors.redAccent).withOpacity(0.4)),
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _qedColor(double q) {
    if (q >= 0.7) return Colors.greenAccent;
    if (q >= 0.4) return Colors.amberAccent;
    return Colors.redAccent;
  }
}

// ── Prediction results ───────────────────────────────────────────────────

class PredictionsCard extends StatelessWidget {
  final Map<String, dynamic> predictions;

  const PredictionsCard({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'ML Model Predictions',
      child: Column(
        children: [
          // ── Regression ────────────────────────────────────────────────
          if (predictions['solubility'] != null)
            _SolubilityTile(predictions['solubility']),
          if (predictions['freesolv'] != null)
            _RegTile('Hydration Free Energy', predictions['freesolv'],
                valueKey: 'dG', icon: Icons.thermostat),
          if (predictions['lipo'] != null)
            _RegTile('Lipophilicity (logD)', predictions['lipo'],
                valueKey: 'logD', icon: Icons.oil_barrel),
          // ── Binary classification ──────────────────────────────────────
          if (predictions['bbbp'] != null)
            _BinaryTile('BBB Permeability', predictions['bbbp'], Icons.psychology),
          if (predictions['bace'] != null)
            _BinaryTile('BACE-1 Inhibition', predictions['bace'], Icons.medication),
          if (predictions['hiv'] != null)
            _BinaryTile('HIV Activity', predictions['hiv'], Icons.biotech, invertColor: true),
          // ── Multitask classification ───────────────────────────────────
          if (predictions['tox21'] != null)
            _MultitaskTile('Tox21 Endpoints', predictions['tox21']),
          if (predictions['clintox'] != null)
            _MultitaskTile('ClinTox', predictions['clintox']),
          if (predictions['sider'] != null)
            _MultitaskTile('SIDER Side Effects', predictions['sider']),
          if (predictions['muv'] != null)
            _MultitaskTile('MUV Bioassays', predictions['muv']),
        ],
      ),
    );
  }
}

class _SolubilityTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SolubilityTile(this.data);

  @override
  Widget build(BuildContext context) {
    final logS = data['logS'];
    final label = data['label'] ?? '';
    final unc = data['uncertainty'];
    final color = logS != null && logS > -3
        ? Colors.greenAccent
        : logS != null && logS > -5
            ? Colors.amberAccent
            : Colors.redAccent;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.water_drop, color: Colors.blueAccent, size: 20),
      title: const Text('Aqueous Solubility'),
      subtitle: Text(label, style: TextStyle(color: color, fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$logS log(mol/L)',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          if (unc != null)
            Text('± ${unc['std']}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

class _RegTile extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final String valueKey;
  final IconData icon;

  const _RegTile(this.title, this.data, {required this.valueKey, required this.icon});

  @override
  Widget build(BuildContext context) {
    final val = data[valueKey];
    final unit = data['unit'] ?? '';
    final label = data['label'] ?? '';
    final unc = data['uncertainty'];
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.tealAccent, size: 20),
      title: Text(title),
      subtitle: Text(label, style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$val${unit.isNotEmpty ? ' $unit' : ''}',
              style: const TextStyle(
                  color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          if (unc != null && unc['std'] != null)
            Text('± ${unc['std']}',
                style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

class _BinaryTile extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final IconData icon;
  final bool invertColor;

  const _BinaryTile(this.title, this.data, this.icon, {this.invertColor = false});

  @override
  Widget build(BuildContext context) {
    final prob = (data['probability'] as num?)?.toDouble() ?? 0.0;
    final label = data['label'] ?? '';
    final positive = invertColor ? prob < 0.5 : prob >= 0.5;
    final color = positive ? Colors.greenAccent : Colors.redAccent;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.purpleAccent, size: 20),
      title: Text(title),
      subtitle: LinearProgressIndicator(
        value: prob,
        backgroundColor: Colors.white12,
        color: positive ? Colors.greenAccent : Colors.redAccent,
        minHeight: 4,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${(prob * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _MultitaskTile extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const _MultitaskTile(this.title, this.data);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.science, color: Colors.orangeAccent, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: data.entries.map((e) {
        final prob = (e.value['probability'] as num?)?.toDouble() ?? 0.0;
        final isBad = prob >= 0.5;
        final color = isBad ? Colors.redAccent : Colors.greenAccent;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(e.key.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: prob,
                  backgroundColor: Colors.white12,
                  color: color,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text('${(prob * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Alerts card ──────────────────────────────────────────────────────────

class AlertsCard extends StatelessWidget {
  final Map<String, dynamic> alerts;

  const AlertsCard({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final pains = List<String>.from(alerts['pains'] ?? []);
    final brenk = List<String>.from(alerts['brenk'] ?? []);
    final hasAlerts = alerts['has_alerts'] == true;

    return InfoCard(
      title: 'Structural Alerts',
      borderColor: hasAlerts
          ? Colors.orangeAccent.withOpacity(0.5)
          : Colors.greenAccent.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAlerts ? Icons.warning_amber : Icons.verified_outlined,
                color: hasAlerts ? Colors.orangeAccent : Colors.greenAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                hasAlerts
                    ? '${pains.length + brenk.length} alert(s) found'
                    : 'No structural alerts',
                style: TextStyle(
                    color: hasAlerts ? Colors.orangeAccent : Colors.greenAccent,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (pains.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('PAINS:', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: pains
                  .map((p) => Chip(
                        label: Text(p, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange.withOpacity(0.15),
                        side: const BorderSide(color: Colors.orangeAccent, width: 0.5),
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
          if (brenk.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Brenk:', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: brenk
                  .map((b) => Chip(
                        label: Text(b, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.red.withOpacity(0.12),
                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
