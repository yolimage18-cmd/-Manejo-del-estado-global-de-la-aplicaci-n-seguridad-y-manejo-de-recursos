import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/jornada_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/logout_action.dart';

/// Perfil del usuario: sus datos, el estado del permiso de ubicación y
/// las acciones de borrar historial y cerrar sesión.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jornada = context.watch<JornadaProvider>();
    final user = auth.user;
    final session = auth.session;

    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text('Perfil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text('@${user.username}', style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _InfoRow(label: 'Cuenta creada', value: formatDateTime(user.createdAt)),
                if (session != null)
                  _InfoRow(label: 'Sesión vence', value: formatDateTime(session.expiresAt)),
                _InfoRow(label: 'Marcaciones guardadas', value: '${jornada.punches.length}'),
                _InfoRow(label: 'Permiso de ubicación', value: _permissionLabel(jornada.permission)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: jornada.punches.isEmpty ? null : () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: const Text('Borrar mi historial'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => confirmAndLogout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final jornada = context.read<JornadaProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Borrar historial'),
        content: const Text('Se eliminarán todas tus entradas y salidas guardadas en este dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (ok == true) await jornada.clearHistory();
  }

  static String _permissionLabel(PermissionStatus? status) {
    if (status == null) return 'Sin consultar';
    if (status.isGranted) return 'Permitido';
    if (status.isPermanentlyDenied) return 'Bloqueado';
    return 'Pendiente';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
