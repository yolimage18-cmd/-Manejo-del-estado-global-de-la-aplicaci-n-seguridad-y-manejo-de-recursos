import 'package:flutter/material.dart';

import '../models/punch.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Fila de una marcación: ícono (entrada/salida), lugar y hora.
///
/// Muestra el NOMBRE DEL LUGAR (barrio, ciudad o sitio); solo si no se pudo
/// obtener, muestra las coordenadas.
class PunchTile extends StatelessWidget {
  const PunchTile({
    super.key,
    required this.punch,
    this.worked,
    this.showDate = false,
    this.onDelete,
  });

  final Punch punch;

  /// En una SALIDA: duración del tramo que cierra (p. ej. "4 h 17 min").
  final Duration? worked;

  /// Si es `true`, junto a la hora se muestra la fecha ("2 oct").
  final bool showDate;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = punch.isEntry ? AppColors.secondary : AppColors.accent;
    final detail = worked == null
        ? punch.whereLabel
        : '${punch.whereLabel} · ${formatDuration(worked!)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.o(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.o(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              punch.isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  punch.typeLabel,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatTime(punch.time),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              if (showDate)
                Text(
                  formatDayMonth(punch.time),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
            ],
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Eliminar',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
