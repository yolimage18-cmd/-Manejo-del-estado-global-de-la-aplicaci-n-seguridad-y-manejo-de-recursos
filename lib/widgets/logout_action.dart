import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/jornada_provider.dart';
import '../theme/app_theme.dart';

/// Pide confirmación y cierra sesión.
///
/// Orden importante (manejo de recursos):
///  1. Se espera a que termine de guardarse cualquier marcación pendiente.
///  2. Se cierran las pantallas abiertas encima de la principal.
///  3. Se borra el token seguro; el estado global reacciona y descarta la
///     ubicación y el permiso aprobado (se volverá a pedir al ingresar).
Future<void> confirmAndLogout(BuildContext context) async {
  // No se puede salir mientras se está leyendo la ubicación para una marcación.
  if (context.read<JornadaProvider>().isLocating) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Espera un momento: se está guardando tu registro.'),
        ),
      );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Cerrar sesión'),
      content: const Text(
        'Se cerrará tu sesión y se dejará de usar la ubicación. Al volver a ingresar se te pedirá el permiso de nuevo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.accent)),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final jornada = context.read<JornadaProvider>();
  final auth = context.read<AuthProvider>();
  final navigator = Navigator.of(context);

  await jornada.flushPending(); // 1. nada queda sin guardar
  if (jornada.isLocating) return; // empezó una marcación justo ahora: no se sale
  navigator.popUntil((route) => route.isFirst); // 2. cerrar pantallas abiertas
  await auth.logout(); // 3. borrar token y limpiar estado
}
