import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/brand_loading.dart';
import '../../shared/widgets/confirm_delete.dart';
import '../../shared/widgets/empty_state.dart';
import '../../theme/tokens.dart';

class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: BrandAppBar(
        title: 'Palestra',
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/workout/new'),
        child: const Icon(Icons.add),
      ),
      body: plans.when(
        loading: () => const BrandLoadingScreen(message: 'Schede…'),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Padding(
              padding: AppTokens.pagePadding,
              child: EmptyState(
                icon: Icons.fitness_center,
                title: 'Nessuna scheda',
                subtitle:
                    'Crea una scheda per giorno della settimana o con un nome libero.',
              ),
            );
          }
          return ListView.separated(
            padding: AppTokens.pagePadding,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plan = list[index];
              return _PlanTile(plan: plan);
            },
          );
        },
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan});

  final WorkoutPlanView plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('d MMM').format(plan.updatedAt.toLocal());
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          plan.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          plan.kind == WorkoutPlanKind.weekday
              ? '${weekdayLabel(plan.weekday ?? 1)} · ${plan.exerciseCount} esercizi · $date'
              : '${plan.exerciseCount} esercizi · $date',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTokens.textMuted),
        onTap: () => context.push('/workout/${plan.id}'),
        onLongPress: () async {
          final ok = await confirmDelete(
            context,
            title: 'Elimina scheda',
            message: 'Eliminare “${plan.title}”? Non si può annullare.',
          );
          if (ok) {
            await ref.read(workoutRepositoryProvider).deletePlan(plan.id);
          }
        },
      ),
    );
  }
}
