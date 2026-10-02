import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'router.dart';
import 'shared/widgets/brand_loading.dart';
import 'theme/app_theme.dart';

class GymApp extends ConsumerStatefulWidget {
  const GymApp({super.key});

  @override
  ConsumerState<GymApp> createState() => _GymAppState();
}

class _GymAppState extends ConsumerState<GymApp> with WidgetsBindingObserver {
  late final _router = createRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nessun lavoro in background: i Timer UI (recupero) si fermano da soli
    // se la schermata è disposed; Drift non fa polling di rete.
    // Qui evitiamo solo lavoro extra quando l'app non è foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Placeholder esplicito: niente sync/analytics in background.
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedReadyProvider);

    return MaterialApp.router(
      title: 'Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      builder: (context, child) {
        return seed.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const BrandLoadingScreen(message: 'Preparazione…'),
          error: (e, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossibile inizializzare i dati locali.\n$e',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
