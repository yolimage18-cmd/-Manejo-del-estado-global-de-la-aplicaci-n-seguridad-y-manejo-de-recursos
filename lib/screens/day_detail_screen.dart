import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/jornada_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/work_time.dart';
import '../widgets/app_card.dart';
import '../widgets/punch_tile.dart';

/// Detalle de un día: horas trabajadas y todas sus marcaciones con el lugar.
/// Pantalla PROTEGIDA: siempre se abre dentro de un `AuthGuard`
/// (ver history_tab.dart).
class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.day});

  final DateTime day;

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final jornada = context.read<JornadaProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Eliminar registro'),
        content: const Text('Este registro se borrará de tu historial. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (ok == true) await jornada.deletePunch(id);
  }

  @override
  Widget build(BuildContext context) {
    final jornada = context.watch<JornadaProvider>();
    final now = DateTime.now();

    final summaries = summarize(jornada.punches, now).where((s) => isSameDay(s.day, day));
    final summary = summaries.isEmpty ? null : summaries.first;

    // Duración de cada tramo cerrado (para mostrarla en la salida).
    final segmentByExit = <String, Duration>{};
    for (final s in jornada.segments) {
      final exit = s.exit;
      if (exit != null) segmentByExit[exit.id] = exit.time.difference(s.start);
    }

    return Scaffold(
      appBar: AppBar(title: Text('${weekdayLong(day)} ${formatDayMonth(day)}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  formatDuration(summary?.worked ?? Duration.zero),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary == null
                      ? 'Sin registros este día'
                      : (summary.inProgress ? 'Jornada en curso' : 'Jornada cerrada'),
                  style: TextStyle(color: Colors.white.withAlpha(230)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text('Registros', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (summary == null)
            const AppCard(
              child: Text(
                'No hay marcaciones en este día.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            for (final p in summary.punches)
              PunchTile(
                punch: p,
                worked: segmentByExit[p.id],
                onDelete: () => _confirmDelete(context, p.id),
              ),
        ],
      ),
    );
  }
}
