import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Franja de aviso (error, advertencia o información) con ícono de color.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.color = AppColors.sun,
    this.icon = Icons.info_outline_rounded,
    this.onClose,
  });

  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.o(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.o(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
