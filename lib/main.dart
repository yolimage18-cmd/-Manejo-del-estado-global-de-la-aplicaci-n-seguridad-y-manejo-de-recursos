import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/jornada_provider.dart';
import 'services/auth_service.dart';
import 'services/place_service.dart';
import 'services/punch_storage.dart';
import 'services/secure_store.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Raíz de la app. Aquí se registran los GESTORES DE ESTADO GLOBAL
/// (Provider) para que cualquier pantalla pueda leerlos:
///
///   AuthProvider     -> sesión del usuario (login, token, logout)
///   JornadaProvider  -> entradas/salidas + GPS (escucha a AuthProvider)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          // Al crearse, intenta recuperar la sesión guardada (token seguro).
          create: (_) => AuthProvider(AuthService(SecureStore()))..restoreSession(),
        ),
        ChangeNotifierProvider<JornadaProvider>(
          lazy: false, // se crea desde el inicio para escuchar los cambios de sesión
          create: (ctx) => JornadaProvider(
            auth: ctx.read<AuthProvider>(),
            storage: PunchStorage(),
            placeService: PlaceService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
