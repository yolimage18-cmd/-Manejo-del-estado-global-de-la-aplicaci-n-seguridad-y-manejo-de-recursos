import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

/// GUARDIÁN DE RUTAS (Tarea 02, seguridad): evita ver pantallas protegidas
/// sin estar autenticado.
///
/// Se usa en dos lugares:
///  - `AuthGate` envuelve la pantalla principal.
///  - Cada pantalla secundaria (p. ej. el detalle de un día) se
///    abre envuelta en un `AuthGuard`. Si la sesión desaparece mientras
///    está abierta, la pantalla protegida NO se construye: se regresa al login.
class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select<AuthProvider, bool>((auth) => auth.isAuthenticated);

    if (allowed) return child;

    // Sin sesión: se cierran las rutas apiladas y se muestra el login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    return const LoginScreen();
  }
}
