import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Bottone primario grande (stile Recupero/Allenati).
class BigPrimaryButton extends StatelessWidget {
  const BigPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: tonal ? AppTokens.surfaceHigh : AppTokens.accent,
      foregroundColor: tonal ? AppTokens.text : AppTokens.bg,
      disabledBackgroundColor: AppTokens.surfaceHigh,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      minimumSize: const Size.fromHeight(64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    );

    if (icon != null) {
      return SizedBox(
        width: double.infinity,
        height: 64,
        child: tonal
            ? FilledButton.tonalIcon(
                style: style,
                onPressed: onPressed,
                icon: Icon(icon, size: 28),
                label: Text(label),
              )
            : FilledButton.icon(
                style: style,
                onPressed: onPressed,
                icon: Icon(icon, size: 28),
                label: Text(label),
              ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

/// Bottone outlined grande.
class BigOutlinedButton extends StatelessWidget {
  const BigOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppTokens.text,
      side: const BorderSide(color: AppTokens.surfaceHigh, width: 1.5),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      minimumSize: const Size.fromHeight(64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: icon != null
          ? OutlinedButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon, size: 28),
              label: Text(label),
            )
          : OutlinedButton(
              style: style,
              onPressed: onPressed,
              child: Text(label),
            ),
    );
  }
}
