/// Validaciones de formularios (ver Ejercicio 6 del módulo: Formulario con validación).
class Validators {
  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa un nombre de usuario';
    if (text.length < 3) return 'Mínimo 3 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(text)) {
      return 'Solo letras, números, punto y guion bajo';
    }
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu nombre';
    if (text.length < 2) return 'Escribe un nombre válido';
    return null;
  }

  /// Contraseña al REGISTRARSE: mínimo 8 caracteres, con letras y números.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa una contraseña';
    if (text.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) return 'Incluye al menos una letra';
    if (!RegExp(r'[0-9]').hasMatch(text)) return 'Incluye al menos un número';
    return null;
  }

  /// Contraseña al INICIAR SESIÓN: solo que no esté vacía.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
