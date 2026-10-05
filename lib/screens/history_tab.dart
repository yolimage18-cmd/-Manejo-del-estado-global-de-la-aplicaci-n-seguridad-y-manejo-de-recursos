import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/jornada_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/work_time.dart';
import '../widgets/app_card.dart';
import '../widgets/auth_guard.dart';
import 'day_detail_screen.dart';

/// Historial: lista de días con sus horas trabajadas. Al tocar un día se abre
/// su detalle (pantalla protegida).
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final jornada = context.watch<JornadaProvider>();
    final now = DateTime.now();
    final days = summarize(jornada.punches, now);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('Historial', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 14),
            child: Text(
              'Toca un día para ver sus registros',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
          ),
          if (days.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Todavía no hay registros. Marca tu primera entrada en Inicio.',
                        style: TextStyle(color: AppColors.textMuted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final day in days) _DayTile(summary: day, now: now),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Fila de un día
// ---------------------------------------------------------------------

class _DayTile extends StatelessWidget {
  const _DayTile({required this.summary, required this.now});

  final DaySummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(summary.day, now);
    final entries = summary.punches.where((p) => p.isEntry).length;
    final exits = summary.punches.length - entries;

    final first = summary.firstEntry;
    final last = summary.lastExit;

    late final String title;
    late final String subtitle;

    if (summary.inProgress) {
      title = 'En curso';
      subtitle = '$entries ${entries == 1 ? 'entrada' : 'entradas'} · '
          '$exits ${exits == 1 ? 'salida' : 'salidas'}';
    } else {
      title = 'Jornada completa';
      subtitle = (first != null && last != null)
          ? '${formatTime(first.time)} – ${formatTime(last.time)}'
          : '${summary.punches.length} ${summary.punches.length == 1 ? 'registro' : 'registros'}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              // Pantalla protegida: se abre dentro de un AuthGuard.
              builder: (_) => AuthGuard(child: DayDetailScreen(day: summary.day)),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.o(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${summary.day.day}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isToday ? 'HOY' : weekdayShort(summary.day).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              formatDuration(summary.worked),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: summary.inProgress ? AppColors.secondary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
