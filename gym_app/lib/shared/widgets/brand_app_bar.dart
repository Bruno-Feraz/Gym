import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      titleSpacing: 16,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/brand/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              cacheWidth: 84,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Container(
                width: 28,
                height: 28,
                color: AppTokens.bg,
                alignment: Alignment.center,
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: AppTokens.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      actions: actions,
    );
  }
}
