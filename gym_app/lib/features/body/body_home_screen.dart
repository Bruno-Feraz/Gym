import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/body.dart';
import '../../domain/models/enums.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../theme/tokens.dart';

class BodyHomeScreen extends ConsumerStatefulWidget {
  const BodyHomeScreen({super.key});

  @override
  ConsumerState<BodyHomeScreen> createState() => _BodyHomeScreenState();
}

class _BodyHomeScreenState extends ConsumerState<BodyHomeScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  final _manualKcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();

  BiologicalSex? _sex;
  ActivityLevel _activity = ActivityLevel.moderate;
  bool _useManualKcal = false;
  bool _useManualMacros = false;
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    _manualKcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  void _hydrate(BodyProfileView? p) {
    if (_hydrated || p == null) return;
    _weight.text = _fmt(p.weightKg);
    _height.text = _fmt(p.heightCm);
    _age.text = p.ageYears?.toString() ?? '';
    _manualKcal.text = _fmt(p.manualKcalTarget);
    _protein.text = _fmt(p.manualProteinG);
    _carbs.text = _fmt(p.manualCarbsG);
    _fat.text = _fmt(p.manualFatG);
    _fiber.text = _fmt(p.manualFiberG);
    _sex = p.sex;
    _activity = p.activity ?? ActivityLevel.moderate;
    _useManualKcal = p.manualKcalTarget != null && p.manualKcalTarget! > 0;
    _useManualMacros = p.hasManualMacros;
    _hydrated = true;
  }

  String _fmt(double? v) {
    if (v == null) return '';
    return v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final height = double.tryParse(_height.text.trim().replaceAll(',', '.'));
    final age = int.tryParse(_age.text.trim());
    final manual = _useManualKcal
        ? double.tryParse(_manualKcal.text.trim().replaceAll(',', '.'))
        : null;

    await ref.read(bodyRepositoryProvider).upsertProfile(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          sex: _sex,
          activity: _activity,
          manualKcalTarget: manual,
          clearManualTarget: !_useManualKcal,
          manualProteinG: _useManualMacros
              ? double.tryParse(_protein.text.trim().replaceAll(',', '.'))
              : null,
          manualCarbsG: _useManualMacros
              ? double.tryParse(_carbs.text.trim().replaceAll(',', '.'))
              : null,
          manualFatG: _useManualMacros
              ? double.tryParse(_fat.text.trim().replaceAll(',', '.'))
              : null,
          manualFiberG: _useManualMacros
              ? double.tryParse(_fiber.text.trim().replaceAll(',', '.'))
              : null,
          clearManualMacros: !_useManualMacros,
        );

    if (mounted) {
      setState(() {
        _saving = false;
        _hydrated = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo salvato')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(bodyProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (!_hydrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hydrate(profile));
      });
    }

    final target = profile?.resolvedTarget;
    final macros = profile?.resolvedMacros;

    return Scaffold(
      appBar: BrandAppBar(
        title: 'Dieta',
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: AppTokens.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target calorico',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    target != null
                        ? '${target.kcal.round()} kcal / giorno'
                        : 'Imposta le misure o un target manuale',
                    style: target != null
                        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                        : const TextStyle(color: AppTokens.textMuted),
                  ),
                  if (target != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      target.source == TargetSource.manual
                          ? 'Origine: manuale'
                          : 'Origine: stima Mifflin–St Jeor',
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (macros != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Target macro',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'P ${macros.proteinG.round()} g · C ${macros.carbsG.round()} g · F ${macros.fatG.round()} g · Fibre ${macros.fiberG.round()} g',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      macros.source == TargetSource.manual
                          ? 'Origine: manuale'
                          : 'Origine: stima da peso/kcal',
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Target kcal manuale'),
            value: _useManualKcal,
            onChanged: (v) => setState(() => _useManualKcal = v),
          ),
          if (_useManualKcal) ...[
            TextField(
              controller: _manualKcal,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Calorie giornaliere',
                suffixText: 'kcal',
              ),
            ),
            const SizedBox(height: 12),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Target macro manuale'),
            subtitle: const Text(
              'Proteine, carboidrati, grassi, fibre',
              style: TextStyle(color: AppTokens.textMuted),
            ),
            value: _useManualMacros,
            onChanged: (v) => setState(() => _useManualMacros = v),
          ),
          if (_useManualMacros) ...[
            TextField(
              controller: _protein,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Proteine',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbs,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Carboidrati',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fat,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Grassi',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fiber,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Fibre',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text(
            'Misure corporee',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTokens.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Altezza',
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Età',
              suffixText: 'anni',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BiologicalSex?>(
            value: _sex,
            decoration: const InputDecoration(labelText: 'Sesso'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Non specificato')),
              DropdownMenuItem(
                value: BiologicalSex.female,
                child: Text('Femmina'),
              ),
              DropdownMenuItem(
                value: BiologicalSex.male,
                child: Text('Maschio'),
              ),
              DropdownMenuItem(
                value: BiologicalSex.other,
                child: Text('Altro'),
              ),
            ],
            onChanged: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            value: _activity,
            decoration: const InputDecoration(labelText: 'Attività'),
            items: const [
              DropdownMenuItem(
                value: ActivityLevel.sedentary,
                child: Text('Sedentario'),
              ),
              DropdownMenuItem(
                value: ActivityLevel.light,
                child: Text('Leggera'),
              ),
              DropdownMenuItem(
                value: ActivityLevel.moderate,
                child: Text('Moderata'),
              ),
              DropdownMenuItem(
                value: ActivityLevel.active,
                child: Text('Attiva'),
              ),
              DropdownMenuItem(
                value: ActivityLevel.veryActive,
                child: Text('Molto attiva'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _activity = v);
            },
          ),
          const SizedBox(height: 24),
          BigPrimaryButton(
            label: 'Salva',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Le stime caloriche e dei macro sono indicative e non sostituiscono il parere di un professionista della salute.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.textMuted,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
