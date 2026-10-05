import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/punch.dart';
import '../providers/auth_provider.dart';
import '../providers/jornada_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/info_banner.dart';
import '../widgets/location_access.dart';
import '../widgets/logout_action.dart';
import '../widgets/progress_ring.dart';
import '../widgets/punch_tile.dart';

/// Pantalla principal: información PERSONALIZADA del usuario autenticado
/// (saludo con su nombre, horas trabajadas hoy, sus registros) y los
/// botones de Entrada / Salida que usan el recurso GPS.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Refresca las horas trabajadas cada 30 s mientras la jornada está abierta.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && context.read<JornadaProvider>().isWorking) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel(); // MANEJO DE RECURSOS: se libera el temporizador
    super.dispose();
  }

  Future<void> _punch(PunchType type) async {
    final jornada = context.read<JornadaProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // El permiso se pide SOLO ahora, cuando el usuario quiere marcar.
    if (!await ensureLocationAccess(context)) return;

    final item = await jornada.registerPunch(type);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          item != null
              ? '${item.typeLabel} registrada en ${item.whereLabel}'
              : (jornada.message ?? 'No se pudo registrar la marcación.'),
        ),
      ),
    );
  }

  Future<void> _locateOnly() async {
    if (!await ensureLocationAccess(context)) return;
    if (!mounted) return;
    await context.read<JornadaProvider>().locateOnce();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AppUser?>((a) => a.user);
    final session = context.select<AuthProvider, Session?>((a) => a.session);
    final jornada = context.watch<JornadaProvider>();

    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final worked = jornada.workedToday(now);
    final today = jornada.todayPunches(now);
    final segments = jornada.segments;
    final percent = worked.inSeconds / kDailyGoal.inSeconds;

    // Para cada SALIDA, cuánto duró el tramo que cierra.
    final segmentByExit = <String, Duration>{};
    for (final s in segments) {
      final exit = s.exit;
      if (exit != null) segmentByExit[exit.id] = exit.time.difference(s.start);
    }

    final busy = jornada.isLocating;
    final ready = jornada.punchesLoaded; // el historial ya se leyó del dispositivo

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ---------------- Encabezado + tarjeta de horas ----------------
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 16,
                20,
                60,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withAlpha(60),
                    child: Text(
                      user.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.firstName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '@${user.username} · ${weekdayLong(now)}',
                          style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () => confirmAndLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: -72,
              child: _HoursCard(
                worked: worked,
                percent: percent,
                isWorking: jornada.isWorking,
                since: jornada.workingSince,
                hasToday: today.isNotEmpty,
                lastToday: today.isEmpty ? null : today.first.time,
              ),
            ),
          ],
        ),
        const SizedBox(height: 72 + 18),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (jornada.message != null) ...[
                InfoBanner(
                  text: jornada.message!,
                  color: AppColors.accent,
                  icon: Icons.location_off_rounded,
                  onClose: () => context.read<JornadaProvider>().clearMessage(),
                ),
                const SizedBox(height: 14),
              ],

              // ---------------- Botones Entrada / Salida ----------------
              Row(
                children: [
                  Expanded(
                    child: _PunchButton(
                      label: 'Entrada',
                      icon: Icons.login_rounded,
                      subtitle: !ready
                          ? 'Cargando...'
                          : busy
                              ? 'Buscando lugar...'
                              : (jornada.isWorking ? 'Ya registrada' : 'Toca para marcar'),
                      enabled: ready && !busy && !jornada.isWorking,
                      gradient: AppColors.tealGradient,
                      shadow: AppColors.secondary,
                      loading: busy && !jornada.isWorking,
                      onTap: () => _punch(PunchType.entrada),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PunchButton(
                      label: 'Salida',
                      icon: Icons.logout_rounded,
                      subtitle: !ready
                          ? 'Cargando...'
                          : busy
                              ? 'Buscando lugar...'
                              : (jornada.isWorking ? 'Toca para marcar' : 'Marca entrada primero'),
                      enabled: ready && !busy && jornada.isWorking,
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFFFF8A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shadow: AppColors.accent,
                      loading: busy && jornada.isWorking,
                      onTap: () => _punch(PunchType.salida),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ---------------- Ubicación (nombre del lugar) ----------------
              _LocationCard(onLocate: _locateOnly),

              // ---------------- Registros de hoy ----------------
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 20, 2, 10),
                child: Text(
                  'Registros de hoy',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (today.isEmpty)
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aún no marcas nada hoy. Toca "Entrada" para iniciar tu jornada.',
                          style: TextStyle(color: AppColors.textMuted, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final p in today)
                  PunchTile(punch: p, worked: segmentByExit[p.id]),

              if (session != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Sesión segura activa hasta ${formatDateTime(session.expiresAt)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Tarjeta "Hoy has trabajado"
// =====================================================================

class _HoursCard extends StatelessWidget {
  const _HoursCard({
    required this.worked,
    required this.percent,
    required this.isWorking,
    required this.since,
    required this.hasToday,
    required this.lastToday,
  });

  final Duration worked;
  final double percent;
  final bool isWorking;
  final DateTime? since;
  final bool hasToday;
  final DateTime? lastToday;

  @override
  Widget build(BuildContext context) {
    late final String status;
    late final Color color;

    if (isWorking && since != null) {
      status = 'En jornada · ${describeMoment(since!, DateTime.now())}';
      color = AppColors.success;
    } else if (hasToday && lastToday != null) {
      status = 'Jornada cerrada · ${formatTime(lastToday!)}';
      color = AppColors.primary;
    } else {
      status = 'Sin jornada iniciada';
      color = AppColors.textMuted;
    }

    final percentText = '${(percent * 100).round()}%';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          ProgressRing(
            progress: math.min(1.0, percent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  percentText,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1),
                ),
                Text(
                  'de ${kDailyGoal.inHours} h',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoy has trabajado',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatDuration(worked),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.o(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Botón grande Entrada / Salida
// =====================================================================

class _PunchButton extends StatelessWidget {
  const _PunchButton({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.enabled,
    required this.gradient,
    required this.shadow,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String subtitle;
  final bool enabled;
  final Gradient gradient;
  final Color shadow;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);

    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : const Color(0xFFC9C6DB),
        borderRadius: radius,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: shadow.o(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 28,
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withAlpha(235), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Tarjeta de ubicación: muestra el NOMBRE del lugar (no solo coordenadas)
// =====================================================================

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.onLocate});

  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final jornada = context.watch<JornadaProvider>();
    final position = jornada.lastPosition;
    final place = jornada.lastPlace;

    late final String title;
    late final String detail;

    if (position == null) {
      title = 'Ubicación sin consultar';
      detail = 'Se pide al marcar. No necesitas moverte para obtenerla.';
    } else if (place != null) {
      title = place.title;
      detail = [
        if (place.subtitle.isNotEmpty) place.subtitle,
        '± ${position.accuracy.round()} m',
      ].join(' · ');
    } else if (jornada.isLocating) {
      title = 'Buscando el nombre del lugar...';
      detail = '± ${position.accuracy.round()} m';
    } else {
      title = 'Lugar sin nombre disponible';
      detail = 'Sin internet no se puede obtener el nombre. '
          '${formatCoord(position.latitude)}, ${formatCoord(position.longitude)}';
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.o(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PermissionChip(status: jornada.permission),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: jornada.isLocating ? null : onLocate,
                  icon: const Icon(Icons.my_location_rounded, size: 20),
                  label: Text(position == null ? 'Obtener mi ubicación' : 'Actualizar'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.status});

  final PermissionStatus? status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    if (status == null) {
      label = 'Sin consultar';
      color = AppColors.textMuted;
    } else if (status!.isGranted) {
      label = 'Permitido';
      color = AppColors.success;
    } else if (status!.isPermanentlyDenied) {
      label = 'Bloqueado';
      color = AppColors.accent;
    } else {
      label = 'Pendiente';
      color = AppColors.sun;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.o(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
