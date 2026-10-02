import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/workout.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/brand_loading.dart';
import '../../theme/tokens.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    required this.planId,
    required this.sessionId,
  });

  final String planId;
  final String sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  /// exerciseId → list of (repsCtrl, weightCtrl) per set
  final Map<String, List<_SetControllers>> _sets = {};
  bool _ready = false;
  bool _saving = false;
  List<PlanExerciseView> _exercises = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(workoutRepositoryProvider);
    final planExercises =
        await ref.read(planExercisesProvider(widget.planId).future);
    final existing = await repo.getSessionSets(widget.sessionId);

    for (final ex in planExercises) {
      final fromDb =
          existing.where((s) => s.exerciseId == ex.exerciseId).toList();
      if (fromDb.isNotEmpty) {
        _sets[ex.exerciseId] = fromDb
            .map(
              (s) => _SetControllers(
                reps: TextEditingController(text: '${s.reps}'),
                weight: TextEditingController(
                  text: s.weightKg.toStringAsFixed(
                    s.weightKg.truncateToDouble() == s.weightKg ? 0 : 1,
                  ),
                ),
              ),
            )
            .toList();
      } else {
        final weight = ex.targetWeightKg;
        _sets[ex.exerciseId] = List.generate(
          ex.targetSets,
          (_) => _SetControllers(
            reps: TextEditingController(text: '${ex.targetReps}'),
            weight: TextEditingController(
              text: weight == null
                  ? ''
                  : weight.toStringAsFixed(
                      weight.truncateToDouble() == weight ? 0 : 1,
                    ),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _exercises = planExercises;
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    for (final list in _sets.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save({bool pop = true}) async {
    setState(() => _saving = true);
    final inputs = <SessionSetInput>[];
    for (final entry in _sets.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final c = entry.value[i];
        final reps = int.tryParse(c.reps.text.trim()) ?? 0;
        final weight =
            double.tryParse(c.weight.text.trim().replaceAll(',', '.')) ?? 0;
        if (reps <= 0) continue;
        inputs.add(
          SessionSetInput(
            exerciseId: entry.key,
            setIndex: i,
            reps: reps,
            weightKg: weight,
          ),
        );
      }
    }
    await ref.read(workoutRepositoryProvider).saveSessionSets(
          sessionId: widget.sessionId,
          sets: inputs,
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessione salvata')),
      );
      if (pop) context.go('/workout/${widget.planId}');
    }
  }

  void _addSet(String exerciseId, PlanExerciseView template) {
    setState(() {
      _sets[exerciseId] = [
        ...?_sets[exerciseId],
        _SetControllers(
          reps: TextEditingController(text: '${template.targetReps}'),
          weight: TextEditingController(
            text: template.targetWeightKg?.toString() ?? '',
          ),
        ),
      ];
    });
  }

  void _removeSet(String exerciseId, int index) {
    setState(() {
      final list = _sets[exerciseId];
      if (list == null || list.length <= 1) return;
      list[index].dispose();
      list.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        title: 'Sessione',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/workout/${widget.planId}'),
        ),
        actions: [
          TextButton(
            onPressed: _saving || !_ready ? null : () => _save(),
            child: const Text('Salva'),
          ),
        ],
      ),
      body: !_ready
          ? const BrandLoadingScreen(message: 'Sessione…')
          : ListView(
              padding: AppTokens.pagePadding.copyWith(bottom: 32),
              children: [
                for (final ex in _exercises) ...[
                  Text(
                    ex.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_sets[ex.exerciseId]?.length ?? 0, (i) {
                    final c = _sets[ex.exerciseId]![i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: AppTokens.textMuted),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: c.reps,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Reps',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: c.weight,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'kg',
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeSet(ex.exerciseId, i),
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppTokens.textMuted,
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addSet(ex.exerciseId, ex),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Serie'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                BigPrimaryButton(
                  label: 'Salva sessione',
                  onPressed: _saving ? null : () => _save(),
                ),
              ],
            ),
    );
  }
}

class _SetControllers {
  _SetControllers({required this.reps, required this.weight});
  final TextEditingController reps;
  final TextEditingController weight;

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}
