import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Pantalla de carga: se muestra mientras la app lee el token guardado
/// en el almacenamiento seguro para saber si ya hay una sesión iniciada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoBadge(),
              SizedBox(height: 22),
              Text(
                kAppName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(46),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(90), width: 2),
      ),
      child: const Icon(Icons.timer_rounded, color: Colors.white, size: 52),
    );
  }
}
