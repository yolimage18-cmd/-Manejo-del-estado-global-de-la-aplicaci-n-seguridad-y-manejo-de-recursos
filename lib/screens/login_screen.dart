import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/info_banner.dart';
import 'register_screen.dart';

/// Módulo de autenticación: login con usuario y contraseña.
///
/// Al iniciar sesión correctamente, el AuthProvider cambia el estado global
/// y el AuthGate muestra la pantalla principal (aquí no hay que navegar).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    // Se liberan los controladores para no dejar memoria ocupada.
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthProvider>().login(_userCtrl.text, _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(90), width: 2),
                      ),
                      child: const Icon(Icons.timer_rounded, color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      kAppName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu jornada, con hora y lugar',
                      style: TextStyle(color: Colors.white.withAlpha(225), fontSize: 14),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 16),
                            if (auth.notice != null) ...[
                              InfoBanner(
                                text: auth.notice!,
                                color: AppColors.sky,
                                icon: Icons.lock_clock_rounded,
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (auth.errorMessage != null) ...[
                              InfoBanner(
                                text: auth.errorMessage!,
                                color: AppColors.accent,
                                icon: Icons.error_outline_rounded,
                                onClose: () => context.read<AuthProvider>().clearError(),
                              ),
                              const SizedBox(height: 14),
                            ],
                            CustomTextField(
                              controller: _userCtrl,
                              label: 'Usuario',
                              icon: Icons.person_outline_rounded,
                              validator: Validators.username,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _passCtrl,
                              label: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _hidePassword,
                              validator: Validators.requiredPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: auth.busy ? null : _submit,
                              child: auth.busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: auth.busy
                                  ? null
                                  : () {
                                      context.read<AuthProvider>().clearError();
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (_) => const RegisterScreen()))
                                          .then((_) {
                                        // Al volver, se limpia cualquier error del registro.
                                        if (context.mounted) context.read<AuthProvider>().clearError();
                                      });
                                    },
                              child: const Text('¿No tienes cuenta? Regístrate'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
