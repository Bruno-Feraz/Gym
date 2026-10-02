import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/enums.dart';
import '../../theme/tokens.dart';

Future<void> showShoppingAlertDialog(
  BuildContext context, {
  required ShoppingAlertKind kind,
  required double listKcal,
  required double targetKcal,
}) {
  final isOver = kind == ShoppingAlertKind.over;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isOver ? 'Sopra il fabbisogno' : 'Sotto il fabbisogno'),
      content: Text(
        isOver
            ? 'La lista supera il target (~${listKcal.round()} kcal vs ${targetKcal.round()}).'
            : 'La lista è molto sotto il target (~${listKcal.round()} kcal vs ${targetKcal.round()}).',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Chiudi'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isOver ? AppTokens.warning : AppTokens.accent,
            foregroundColor: AppTokens.bg,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            context.go('/body');
          },
          child: const Text('Vai a Dieta'),
        ),
      ],
    ),
  );
}
