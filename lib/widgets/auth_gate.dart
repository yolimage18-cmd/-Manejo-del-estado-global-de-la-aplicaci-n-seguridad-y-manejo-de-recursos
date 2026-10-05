import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/splash_screen.dart';
import 'auth_guard.dart';

/// Puerta de entrada de la app: decide qué pantalla mostrar según el
/// ESTADO GLOBAL de autenticación.
///
///   unknown          -> Splash (se está leyendo el token guardado)
///   unauthenticated  -> Login
///   authenticated    -> Pantalla principal (protegida por AuthGuard)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((auth) => auth.status);

    switch (status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const AuthGuard(child: MainShell());
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
