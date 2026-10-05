import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/info_banner.dart';

/// Crea una cuenta local (la contraseña se guarda solo como hash con sal).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().register(
          username: _userCtrl.text,
          displayName: _nameCtrl.text,
          password: _passCtrl.text,
        );

    // Si salió bien, la app ya inició sesión: se cierra este formulario
    // y el AuthGate (debajo) ya muestra la pantalla principal.
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bienvenida/o a Fichaje',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Crea tu cuenta para guardar tus entradas y salidas.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
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
                  controller: _nameCtrl,
                  label: 'Tu nombre',
                  icon: Icons.badge_outlined,
                  validator: Validators.displayName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _userCtrl,
                  label: 'Usuario',
                  icon: Icons.person_outline_rounded,
                  validator: Validators.username,
                  textInputAction: TextInputAction.next,
                  helperText: 'Con este usuario iniciarás sesión.',
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _passCtrl,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _hidePassword,
                  validator: Validators.newPassword,
                  textInputAction: TextInputAction.next,
                  helperText: 'Mínimo 8 caracteres, con letras y números.',
                  suffix: IconButton(
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _confirmCtrl,
                  label: 'Confirmar contraseña',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _hidePassword,
                  validator: (value) => Validators.confirmPassword(value, _passCtrl.text),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
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
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
