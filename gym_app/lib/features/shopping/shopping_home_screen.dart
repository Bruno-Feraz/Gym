import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/shopping.dart';
import '../../domain/services/alert_policy.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/brand_loading.dart';
import '../../shared/widgets/confirm_delete.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shopping_alert_dialog.dart';
import '../../theme/tokens.dart';

class ShoppingHomeScreen extends ConsumerStatefulWidget {
  const ShoppingHomeScreen({super.key});

  @override
  ConsumerState<ShoppingHomeScreen> createState() => _ShoppingHomeScreenState();
}

class _ShoppingHomeScreenState extends ConsumerState<ShoppingHomeScreen> {
  String? _listId;
  ShoppingAlertKind? _lastShownKind;
  double? _lastEvaluatedTotal;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final id =
        await ref.read(shoppingRepositoryProvider).ensureActiveList();
    if (mounted) {
      setState(() {
        _listId = id;
        _bootstrapped = true;
      });
    }
  }

  Future<void> _evaluateAlert(double totalKcal) async {
    if (_lastEvaluatedTotal == totalKcal) return;
    _lastEvaluatedTotal = totalKcal;

    final profile = ref.read(bodyProfileProvider).valueOrNull;
    final target = profile?.resolvedTarget?.kcal;
    final thresholds =
        await ref.read(shoppingRepositoryProvider).loadThresholds();
    final kind = AlertPolicy.evaluate(
      targetKcal: target,
      listTotalKcal: totalKcal,
      thresholds: thresholds,
    );
    if (kind == ShoppingAlertKind.none) {
      _lastShownKind = null;
      return;
    }
    if (kind == _lastShownKind || !mounted) return;
    _lastShownKind = kind;
    await showShoppingAlertDialog(
      context,
      kind: kind,
      listKcal: totalKcal,
      targetKcal: target!,
    );
  }

  Future<void> _addFood() async {
    final listId = _listId;
    if (listId == null) return;

    final food = await showModalBottomSheet<FoodOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface,
      builder: (_) => const _FoodPickerSheet(),
    );
    if (food == null || !mounted) return;

    final grams = await showDialog<double>(
      context: context,
      builder: (ctx) => _GramsDialog(foodName: food.name),
    );
    if (grams == null) return;

    await ref.read(shoppingRepositoryProvider).addEntry(
          listId: listId,
          foodId: food.id,
          grams: grams,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped || _listId == null) {
      return const BrandLoadingScreen(message: 'Spesa…');
    }

    final entriesAsync = ref.watch(shoppingEntriesProvider(_listId!));
    final profile = ref.watch(bodyProfileProvider).valueOrNull;
    final target = profile?.resolvedTarget;
    final macros = profile?.resolvedMacros;

    return Scaffold(
      appBar: BrandAppBar(
        title: 'Spesa',
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BigPrimaryButton(
          label: 'Aggiungi alimento',
          icon: Icons.add,
          onPressed: _addFood,
        ),
      ),
      body: entriesAsync.when(
        loading: () => const BrandLoadingScreen(message: 'Lista…'),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (entries) {
          final totalKcal = entries.fold<double>(0, (a, e) => a + e.kcal);
          final totalP = entries.fold<double>(0, (a, e) => a + e.protein);
          final totalC = entries.fold<double>(0, (a, e) => a + e.carbs);
          final totalF = entries.fold<double>(0, (a, e) => a + e.fat);
          final totalFiber = entries.fold<double>(0, (a, e) => a + e.fiber);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (entries.isNotEmpty) _evaluateAlert(totalKcal);
          });

          return Column(
            children: [
              Padding(
                padding: AppTokens.pagePadding.copyWith(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${totalKcal.round()} kcal',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          target == null
                              ? 'Target kcal: impostalo in Dieta'
                              : 'Target kcal: ${target.kcal.round()}',
                          style: const TextStyle(color: AppTokens.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nutrienti lista',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Proteine ${totalP.round()} g'
                          '${macros != null ? ' / ${macros.proteinG.round()} g' : ''}',
                        ),
                        Text(
                          'Carboidrati ${totalC.round()} g'
                          '${macros != null ? ' / ${macros.carbsG.round()} g' : ''}',
                        ),
                        Text(
                          'Grassi ${totalF.round()} g'
                          '${macros != null ? ' / ${macros.fatG.round()} g' : ''}',
                        ),
                        Text(
                          'Fibre ${totalFiber.round()} g'
                          '${macros != null ? ' / ${macros.fiberG.round()} g' : ''}',
                        ),
                        if (macros == null) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Target macro: imposta peso/altezza/età in Dieta (o valori manuali).',
                            style: TextStyle(
                              color: AppTokens.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Padding(
                        padding: AppTokens.pagePadding,
                        child: EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          title: 'Lista vuota',
                          subtitle:
                              'Aggiungi alimenti: vedrai kcal, proteine, carboidrati, grassi e fibre.',
                        ),
                      )
                    : ListView.separated(
                        padding: AppTokens.pagePadding.copyWith(bottom: 120),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          return Card(
                            child: CheckboxListTile(
                              value: e.checked,
                              onChanged: (v) {
                                ref
                                    .read(shoppingRepositoryProvider)
                                    .setChecked(e.id, v ?? false);
                              },
                              title: Text(
                                e.foodName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: e.checked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                '${e.grams.round()} g · ${e.kcal.round()} kcal\n'
                                'P ${e.protein.round()} · C ${e.carbs.round()} · F ${e.fat.round()} · Fibre ${e.fiber.round()} g',
                                style: const TextStyle(
                                  color: AppTokens.textMuted,
                                ),
                              ),
                              isThreeLine: true,
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await confirmDelete(
                                    context,
                                    title: 'Rimuovi',
                                    message: 'Rimuovere “${e.foodName}”?',
                                  );
                                  if (ok) {
                                    await ref
                                        .read(shoppingRepositoryProvider)
                                        .deleteEntry(e.id);
                                    _lastShownKind = null;
                                    _lastEvaluatedTotal = null;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GramsDialog extends StatefulWidget {
  const _GramsDialog({required this.foodName});
  final String foodName;

  @override
  State<_GramsDialog> createState() => _GramsDialogState();
}

class _GramsDialogState extends State<_GramsDialog> {
  final _ctrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.foodName),
      content: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Quantità',
          suffixText: 'g',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final g =
                double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
            if (g != null && g > 0) Navigator.pop(context, g);
          },
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

class _FoodPickerSheet extends ConsumerStatefulWidget {
  const _FoodPickerSheet();

  @override
  ConsumerState<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<_FoodPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createCustom() async {
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController(text: '100');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alimento custom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'kcal / 100 g',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final kcal =
        double.tryParse(kcalCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    nameCtrl.dispose();
    kcalCtrl.dispose();
    if (name.isEmpty || kcal <= 0 || !mounted) return;

    final id = await ref.read(shoppingRepositoryProvider).addCustomFood(
          name: name,
          kcalPer100g: kcal,
        );
    if (mounted) {
      Navigator.pop(
        context,
        FoodOption(
          id: id,
          name: name,
          isCustom: true,
          kcalPer100g: kcal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider);
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
                'Scegli alimento',
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
                child: foods.when(
                  loading: () => const InlineLoader(),
                  error: (e, _) => Text('$e'),
                  data: (list) {
                    final filtered = q.isEmpty
                        ? list
                        : list
                            .where((f) => f.name.toLowerCase().contains(q))
                            .toList();
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final f = filtered[i];
                        return ListTile(
                          title: Text(f.name),
                          subtitle: Text(
                            '${f.kcalPer100g.round()} kcal / 100 g',
                            style: const TextStyle(color: AppTokens.textMuted),
                          ),
                          onTap: () => Navigator.pop(context, f),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.text,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _createCustom,
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text('Nuovo alimento custom'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
