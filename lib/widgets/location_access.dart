import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/jornada_provider.dart';
import '../theme/app_theme.dart';

/// Flujo EXPLÍCITO de permisos de ubicación (Tarea 02, punto 3).
///
/// Sigue las "mejores prácticas" del módulo (permission_handler):
///  1. Primero CONSULTA el estado (sin molestar al usuario).
///  2. EXPLICA por qué se necesita la ubicación: este aviso se muestra en
///     cada sesión nueva (al volver a ingresar se pide otra vez) y siempre
///     que falte el permiso.
///  3. Solo si hace falta, muestra el cuadro del sistema para pedir el permiso.
///  4. Si el usuario lo bloqueó para siempre, lo guía a Ajustes (openAppSettings).
///  5. Verifica que el GPS del teléfono esté encendido.
///
/// Devuelve `true` solo si ya se puede leer la ubicación.
Future<bool> ensureLocationAccess(BuildContext context) async {
  final provider = context.read<JornadaProvider>();

  var status = await provider.refreshPermission();

  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;
    await _showSettingsDialog(context);
    return false;
  }

  // El aviso se muestra si falta el permiso o si es una sesión nueva.
  if (!status.isGranted || !provider.locationApprovedThisSession) {
    if (!context.mounted) return false;
    final accepted = await _showRationaleDialog(context);
    if (accepted != true || !context.mounted) return false;
  }

  if (!status.isGranted) {
    status = await provider.requestPermission();
    if (!context.mounted) return false;

    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await _showSettingsDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin el permiso de ubicación no puedo registrar tu entrada o salida.'),
          ),
        );
      }
      return false;
    }
  }

  provider.approveLocationThisSession();

  // Permiso concedido: ahora, ¿está encendido el GPS del teléfono?
  if (!await Geolocator.isLocationServiceEnabled()) {
    if (!context.mounted) return false;
    await _showGpsOffDialog(context);
    return false;
  }

  return true;
}

Future<bool?> _showRationaleDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary.o(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 30),
      ),
      title: const Text('¿Permitir usar tu ubicación?'),
      content: const Text(
        'Fichaje necesita tu ubicación solo para guardar el lugar donde '
        'marcas tu entrada o salida. La app la lee cuando tú lo pides y deja '
        'de usar el GPS al terminar o al cerrar sesión.',
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}

Future<void> _showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Permiso bloqueado'),
      content: const Text(
        'Bloqueaste el permiso de ubicación. Para marcar entrada o salida ábrelo '
        'en Ajustes → Permisos → Ubicación y elige "Permitir solo mientras '
        'se usa la app".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            openAppSettings();
          },
          child: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
}

Future<void> _showGpsOffDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('GPS apagado'),
      content: const Text(
        'El servicio de ubicación del dispositivo está apagado. Actívalo '
        'para poder marcar tu entrada o salida.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Geolocator.openLocationSettings();
          },
          child: const Text('Activar GPS'),
        ),
      ],
    ),
  );
}
