import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/workout.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/brand_loading.dart';
import '../../shared/widgets/confirm_delete.dart';
import '../../shared/widgets/empty_state.dart';
import '../../theme/tokens.dart';
import 'recovery_screen.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final exercises = ref.watch(planExercisesProvider(planId));

    final plan = plans.maybeWhen(
      data: (list) {
        try {
          return list.firstWhere((p) => p.id == planId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: BrandAppBar(
        title: plan?.title ?? 'Scheda',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/workout'),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifica',
            onPressed: () => context.push('/workout/$planId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Elimina',
            onPressed: () async {
              final ok = await confirmDelete(
                context,
                title: 'Elimina scheda',
                message: 'Eliminare questa scheda?',
              );
              if (ok && context.mounted) {
                await ref.read(workoutRepositoryProvider).deletePlan(planId);
                if (context.mounted) context.go('/workout');
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 64,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.surfaceHigh,
                    foregroundColor: AppTokens.text,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RecoveryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timer_outlined, size: 28),
                  label: const Text('Recupero'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 64,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.accent,
                    foregroundColor: AppTokens.bg,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                  ),
                  onPressed: () => _startSession(context, ref),
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text('Allenati'),
                ),
              ),
            ),
          ],
        ),
      ),
      body: exercises.when(
        loading: () => const BrandLoadingScreen(message: 'Scheda…'),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: EmptyState(
                    icon: Icons.list_alt,
                    title: 'Nessun esercizio',
                    subtitle: 'Aggiungi esercizi con serie, ripetizioni e peso target.',
                  ),
                ),
                Padding(
                  padding: AppTokens.pagePadding,
                  child: BigOutlinedButton(
                    label: 'Aggiungi esercizio',
                    icon: Icons.add,
                    onPressed: () => _addExercise(context, ref),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            );
          }
          return ListView(
            padding: AppTokens.pagePadding.copyWith(bottom: 120),
            children: [
              if (plan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    plan.subtitle,
                    style: const TextStyle(color: AppTokens.textMuted),
                  ),
                ),
              for (final ex in list) _ExerciseTile(planId: planId, exercise: ex),
              const SizedBox(height: 12),
              BigOutlinedButton(
                label: 'Aggiungi esercizio',
                icon: Icons.add,
                onPressed: () => _addExercise(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startSession(BuildContext context, WidgetRef ref) async {
    final list = await ref.read(planExercisesProvider(planId).future);
    if (list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aggiungi almeno un esercizio')),
        );
      }
      return;
    }
    final sessionId =
        await ref.read(workoutRepositoryProvider).startSession(planId);
    if (context.mounted) {
      context.push('/workout/$planId/session/$sessionId');
    }
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<ExerciseOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface,
      builder: (ctx) => const _ExercisePickerSheet(),
    );
    if (selected == null || !context.mounted) return;

    final targets = await showDialog<_Targets>(
      context: context,
      builder: (ctx) => _TargetsDialog(exerciseName: selected.name),
    );
    if (targets == null) return;

    await ref.read(workoutRepositoryProvider).addExerciseToPlan(
          planId: planId,
          exerciseId: selected.id,
          targetSets: targets.sets,
          targetReps: targets.reps,
          targetWeightKg: targets.weight,
        );
  }
}

class _ExerciseTile extends ConsumerWidget {
  const _ExerciseTile({required this.planId, required this.exercise});

  final String planId;
  final PlanExerciseView exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = exercise.targetWeightKg;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          exercise.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${exercise.targetSets}×${exercise.targetReps}'
          '${weight != null ? ' · ${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} kg' : ''}',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final repo = ref.read(workoutRepositoryProvider);
            if (value == 'progress') {
              context.push('/workout/exercise/${exercise.exerciseId}/progress');
            } else if (value == 'edit') {
              final targets = await showDialog<_Targets>(
                context: context,
                builder: (ctx) => _TargetsDialog(
                  exerciseName: exercise.exerciseName,
                  initialSets: exercise.targetSets,
                  initialReps: exercise.targetReps,
                  initialWeight: exercise.targetWeightKg,
                ),
              );
              if (targets != null) {
                await repo.updatePlanExercise(
                  id: exercise.id,
                  targetSets: targets.sets,
                  targetReps: targets.reps,
                  targetWeightKg: targets.weight,
                );
              }
            } else if (value == 'delete') {
              final ok = await confirmDelete(
                context,
                title: 'Rimuovi esercizio',
                message: 'Rimuovere “${exercise.exerciseName}” dalla scheda?',
              );
              if (ok) await repo.removePlanExercise(exercise.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'progress', child: Text('Progressione')),
            PopupMenuItem(value: 'edit', child: Text('Modifica')),
            PopupMenuItem(value: 'delete', child: Text('Rimuovi')),
          ],
        ),
        onTap: () =>
            context.push('/workout/exercise/${exercise.exerciseId}/progress'),
      ),
    );
  }
}

class _Targets {
  const _Targets({required this.sets, required this.reps, this.weight});
  final int sets;
  final int reps;
  final double? weight;
}

class _TargetsDialog extends StatefulWidget {
  const _TargetsDialog({
    required this.exerciseName,
    this.initialSets = 3,
    this.initialReps = 10,
    this.initialWeight,
  });

  final String exerciseName;
  final int initialSets;
  final int initialReps;
  final double? initialWeight;

  @override
  State<_TargetsDialog> createState() => _TargetsDialogState();
}

class _TargetsDialogState extends State<_TargetsDialog> {
  late final _sets = TextEditingController(text: '${widget.initialSets}');
  late final _reps = TextEditingController(text: '${widget.initialReps}');
  late final _weight = TextEditingController(
    text: widget.initialWeight?.toString() ?? '',
  );

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sets,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Serie'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ripetizioni'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Peso kg (opzionale)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final sets = int.tryParse(_sets.text.trim()) ?? 0;
            final reps = int.tryParse(_reps.text.trim()) ?? 0;
            if (sets <= 0 || reps <= 0) return;
            final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
            Navigator.pop(
              context,
              _Targets(sets: sets, reps: reps, weight: w),
            );
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _search = TextEditingController();
  final _custom = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(exercisesProvider);
    final q = _search.text.trim().toLowerCase();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.surfaceHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scegli esercizio',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Cerca…',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: all.when(
                  loading: () => const InlineLoader(),
                  error: (e, _) => Text('$e'),
                  data: (list) {
                    final filtered = q.isEmpty
                        ? list
                        : list
                            .where((e) => e.name.toLowerCase().contains(q))
                            .toList();
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return ListTile(
                          title: Text(e.name),
                          onTap: () => Navigator.pop(context, e),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _custom,
                      decoration: const InputDecoration(
                        hintText: 'Nuovo esercizio custom',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () async {
                      final name = _custom.text.trim();
                      if (name.isEmpty) return;
                      final id = await ref
                          .read(workoutRepositoryProvider)
                          .addCustomExercise(name);
                      if (context.mounted) {
                        Navigator.pop(
                          context,
                          ExerciseOption(id: id, name: name, isCustom: true),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
