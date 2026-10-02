import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Schermata di caricamento brandizzata (logo G + spinner leggero).
class BrandLoadingScreen extends StatelessWidget {
  const BrandLoadingScreen({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/brand/logo.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Text(
                  'G',
                  style: TextStyle(
                    color: AppTokens.text,
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTokens.accent,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: AppTokens.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicatore inline minimo (liste / sheet) — niente logo per non pesare.
class InlineLoader extends StatelessWidget {
  const InlineLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTokens.accent,
        ),
      ),
    );
  }
}
