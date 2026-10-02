import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../domain/models/workout.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/brand_loading.dart';
import '../../shared/widgets/empty_state.dart';
import '../../theme/tokens.dart';

enum _ProgressMetric { weight, volume }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _ProgressMetric _metric = _ProgressMetric.weight;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider(widget.exerciseId));
    final nameFuture = ref
        .watch(workoutRepositoryProvider)
        .getExerciseName(widget.exerciseId);

    return FutureBuilder<String?>(
      future: nameFuture,
      builder: (context, snap) {
        final title = snap.data ?? 'Progressione';
        return Scaffold(
          appBar: BrandAppBar(
            title: title,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: progress.when(
            loading: () => const BrandLoadingScreen(message: 'Progressione…'),
            error: (e, _) => Center(child: Text('Errore: $e')),
            data: (points) {
              if (points.isEmpty) {
                return const Padding(
                  padding: AppTokens.pagePadding,
                  child: EmptyState(
                    icon: Icons.show_chart,
                    title: 'Nessun dato',
                    subtitle:
                        'Completa almeno una sessione con questo esercizio per vedere la progressione.',
                  ),
                );
              }

              final df = DateFormat('d MMM');
              final values = points
                  .map(
                    (p) => _metric == _ProgressMetric.weight
                        ? p.maxWeightKg
                        : p.volume,
                  )
                  .toList();
              final maxY =
                  values.fold<double>(0, (a, b) => a > b ? a : b);
              final spots = <FlSpot>[
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ];

              return ListView(
                padding: AppTokens.pagePadding,
                children: [
                  SegmentedButton<_ProgressMetric>(
                    segments: const [
                      ButtonSegment(
                        value: _ProgressMetric.weight,
                        label: Text('Peso max'),
                        icon: Icon(Icons.fitness_center, size: 18),
                      ),
                      ButtonSegment(
                        value: _ProgressMetric.volume,
                        label: Text('Volume'),
                        icon: Icon(Icons.bar_chart, size: 18),
                      ),
                    ],
                    selected: {_metric},
                    onSelectionChanged: (s) =>
                        setState(() => _metric = s.first),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _metric == _ProgressMetric.weight
                        ? 'Peso massimo per sessione (kg)'
                        : 'Volume per sessione (reps × kg)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTokens.textMuted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: (maxY * 1.15).clamp(10, double.infinity),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppTokens.surfaceHigh,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                  color: AppTokens.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= points.length) {
                                  return const SizedBox.shrink();
                                }
                                if (points.length > 6 &&
                                    i != 0 &&
                                    i != points.length - 1 &&
                                    i % 2 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    df.format(points[i].performedAt.toLocal()),
                                    style: const TextStyle(
                                      color: AppTokens.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTokens.accent,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTokens.accent.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Storico',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTokens.textMuted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final p in points.reversed)
                    _HistoryTile(point: p, dateFormat: df),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.point, required this.dateFormat});

  final ProgressPoint point;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final w = point.maxWeightKg;
    final wLabel =
        w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '$wLabel kg max',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${dateFormat.format(point.performedAt.toLocal())} · volume ${point.volume.toStringAsFixed(0)}',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
      ),
    );
  }
}
