import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/brand_app_bar.dart';
import '../../theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const versionLabel = '0.2.1+3';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        title: 'Impostazioni',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: AppTokens.pagePadding,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text('Guida rapida'),
            subtitle: const Text(
              'Come usare Palestra, Dieta e Spesa',
              style: TextStyle(color: AppTokens.textMuted),
            ),
            onTap: () => _showHelp(context),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Soglie alert spesa'),
            subtitle: Text(
              'Sopra 110% / sotto 80% del target kcal (default)',
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unità'),
            subtitle: Text(
              'kg, cm, kcal, g',
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Privacy e salute'),
            subtitle: Text(
              'I dati restano sul dispositivo. Le stime non sono consiglio medico.',
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sicurezza'),
            subtitle: Text(
              'Segnalazioni: vedi SECURITY.md nel progetto',
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Versione'),
            subtitle: Text(
              versionLabel,
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guida Gym'),
        content: const SingleChildScrollView(
          child: Text(
            'Palestra\n'
            '• Crea una scheda (nome o giorno), aggiungi esercizi.\n'
            '• Allenati: registra serie, reps e peso.\n'
            '• Recupero: timer tra serie o tra esercizi.\n'
            '• Tocca un esercizio per la progressione (peso o volume).\n\n'
            'Dieta\n'
            '• Inserisci peso/altezza/età per stima kcal e macro.\n'
            '• Oppure attiva i target manuali.\n\n'
            'Spesa\n'
            '• Aggiungi alimenti e grammi: vedi P, C, F e fibre.\n'
            '• Se il totale kcal è fuori soglia compare un alert.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
