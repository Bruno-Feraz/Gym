import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/brand_loading.dart';
import '../../theme/tokens.dart';

enum RestKind { betweenSets, betweenExercises }

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen>
    with WidgetsBindingObserver {
  static const _presetsSets = [30, 45, 60, 90, 120, 180];
  static const _presetsExercises = [60, 90, 120, 180, 240, 300];

  int _setsSec = 90;
  int _exercisesSec = 180;
  bool _loaded = false;

  RestKind _activeKind = RestKind.betweenSets;
  int _remaining = 0;
  bool _running = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // In background: pausa il timer per non consumare CPU a vuoto.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_running) {
        _timer?.cancel();
        setState(() => _running = false);
      }
    }
  }

  Future<void> _loadSettings() async {
    final db = ref.read(databaseProvider);
    final rows = await db.select(db.appSettings).get();
    final map = {for (final r in rows) r.key: r.value};
    if (!mounted) return;
    setState(() {
      _setsSec = int.tryParse(map['rest_between_sets_sec'] ?? '') ?? 90;
      _exercisesSec =
          int.tryParse(map['rest_between_exercises_sec'] ?? '') ?? 180;
      _remaining = _setsSec;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    final db = ref.read(databaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'rest_between_sets_sec',
            value: '$_setsSec',
          ),
        );
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'rest_between_exercises_sec',
            value: '$_exercisesSec',
          ),
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _selectKind(RestKind kind) {
    _timer?.cancel();
    setState(() {
      _activeKind = kind;
      _running = false;
      _remaining =
          kind == RestKind.betweenSets ? _setsSec : _exercisesSec;
    });
  }

  void _setDuration(int seconds) {
    _timer?.cancel();
    setState(() {
      if (_activeKind == RestKind.betweenSets) {
        _setsSec = seconds;
      } else {
        _exercisesSec = seconds;
      }
      _remaining = seconds;
      _running = false;
    });
    _persist();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining <= 0) {
      _remaining =
          _activeKind == RestKind.betweenSets ? _setsSec : _exercisesSec;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining =
          _activeKind == RestKind.betweenSets ? _setsSec : _exercisesSec;
    });
  }

  String _format(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _customDuration() async {
    final ctrl = TextEditingController(
      text: '${_activeKind == RestKind.betweenSets ? _setsSec : _exercisesSec}',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Secondi personalizzati'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Secondi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null && n > 0 && n <= 3600) Navigator.pop(ctx, n);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value != null) _setDuration(value);
  }

  @override
  Widget build(BuildContext context) {
    final presets = _activeKind == RestKind.betweenSets
        ? _presetsSets
        : _presetsExercises;
    final current =
        _activeKind == RestKind.betweenSets ? _setsSec : _exercisesSec;

    return Scaffold(
      appBar: BrandAppBar(
        title: 'Recupero',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: !_loaded
          ? const BrandLoadingScreen()
          : ListView(
              padding: AppTokens.pagePadding,
              children: [
                Text(
                  'Tipo di recupero',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTokens.textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<RestKind>(
                  segments: const [
                    ButtonSegment(
                      value: RestKind.betweenSets,
                      label: Text('Tra serie'),
                      icon: Icon(Icons.repeat, size: 18),
                    ),
                    ButtonSegment(
                      value: RestKind.betweenExercises,
                      label: Text('Tra esercizi'),
                      icon: Icon(Icons.swap_vert, size: 18),
                    ),
                  ],
                  selected: {_activeKind},
                  onSelectionChanged: (s) => _selectKind(s.first),
                ),
                const SizedBox(height: 24),
                Text(
                  'Durata',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTokens.textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in presets)
                      ChoiceChip(
                        label: Text(_format(p)),
                        selected: current == p,
                        onSelected: (_) => _setDuration(p),
                      ),
                    ActionChip(
                      label: const Text('Custom'),
                      avatar: const Icon(Icons.edit, size: 16),
                      onPressed: _customDuration,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    _format(_remaining),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                          color: _remaining == 0 && !_running
                              ? AppTokens.success
                              : AppTokens.text,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _running
                        ? 'In corso…'
                        : (_remaining == 0 ? 'Recupero finito' : 'Pronto'),
                    style: const TextStyle(color: AppTokens.textMuted),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: BigOutlinedButton(
                        label: 'Reset',
                        onPressed: _reset,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: BigPrimaryButton(
                        label: _running ? 'Pausa' : 'Avvia',
                        icon: _running ? Icons.pause : Icons.play_arrow,
                        onPressed: _toggle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tempi impostati',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tra serie: ${_format(_setsSec)}',
                          style: const TextStyle(color: AppTokens.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tra esercizi: ${_format(_exercisesSec)}',
                          style: const TextStyle(color: AppTokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
