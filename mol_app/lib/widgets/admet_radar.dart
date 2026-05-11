import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdmetRadarChart extends StatelessWidget {
  final Map<String, double> values; // key → 0..1

  const AdmetRadarChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final labels = values.keys.toList();
    final dataPoints = values.values.toList();

    return Column(
      children: [
        Text(
          'ADMET Profile',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.tealAccent.withOpacity(0.25),
                  borderColor: Colors.tealAccent,
                  borderWidth: 2,
                  entryRadius: 4,
                  dataEntries: dataPoints
                      .map((v) => RadarEntry(value: v))
                      .toList(),
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              gridBorderData: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              tickCount: 4,
              tickBorderData: BorderSide(
                color: Colors.white.withOpacity(0.08),
              ),
              ticksTextStyle: const TextStyle(fontSize: 0),
              getTitle: (index, angle) {
                final label = labels[index % labels.length];
                final val = dataPoints[index % dataPoints.length];
                return RadarChartTitle(
                  text: '$label\n${(val * 100).toStringAsFixed(0)}%',
                  angle: angle,
                  positionPercentageOffset: 0.1,
                );
              },
              titleTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              titlePositionPercentageOffset: 0.15,
            ),
          ),
        ),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: values.entries.map((e) {
            final color = e.value >= 0.7
                ? Colors.greenAccent
                : e.value >= 0.4
                    ? Colors.amberAccent
                    : Colors.redAccent;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.key}: ${(e.value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
