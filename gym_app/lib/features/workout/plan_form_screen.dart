import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../theme/tokens.dart';

class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.planId});

  final String? planId;

  bool get isEdit => planId != null;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _titleCtrl = TextEditingController();
  WorkoutPlanKind _kind = WorkoutPlanKind.named;
  int _weekday = DateTime.now().weekday;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIfEdit() async {
    if (!widget.isEdit || _initialized) return;
    final plan =
        await ref.read(workoutRepositoryProvider).getPlan(widget.planId!);
    if (plan == null || !mounted) return;
    setState(() {
      _titleCtrl.text = plan.title;
      _kind = parsePlanKind(plan.kind);
      _weekday = plan.weekday ?? DateTime.now().weekday;
      _initialized = true;
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome')),
      );
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(workoutRepositoryProvider);
    try {
      if (widget.isEdit) {
        await repo.updatePlan(
          id: widget.planId!,
          title: title,
          kind: _kind,
          weekday: _weekday,
        );
        if (mounted) context.pop();
      } else {
        final id = await repo.createPlan(
          title: title,
          kind: _kind,
          weekday: _weekday,
        );
        if (mounted) context.go('/workout/$id');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && !_initialized) {
      _loadIfEdit();
    }

    return Scaffold(
      appBar: BrandAppBar(
        title: widget.isEdit ? 'Modifica scheda' : 'Nuova scheda',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: AppTokens.pagePadding,
        children: [
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Es. Push A',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tipo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTokens.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<WorkoutPlanKind>(
            segments: const [
              ButtonSegment(
                value: WorkoutPlanKind.named,
                label: Text('Nome'),
                icon: Icon(Icons.label_outline, size: 18),
              ),
              ButtonSegment(
                value: WorkoutPlanKind.weekday,
                label: Text('Giorno'),
                icon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          if (_kind == WorkoutPlanKind.weekday) ...[
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: _weekday,
              decoration: const InputDecoration(labelText: 'Giorno'),
              items: [
                for (var d = 1; d <= 7; d++)
                  DropdownMenuItem(value: d, child: Text(weekdayLabel(d))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _weekday = v);
              },
            ),
          ],
          const SizedBox(height: 32),
          BigPrimaryButton(
            label: widget.isEdit ? 'Salva' : 'Crea scheda',
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
    );
  }
}
