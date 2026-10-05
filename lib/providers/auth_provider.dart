import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// ESTADO GLOBAL #1: quién está autenticado.
///
/// Cualquier pantalla puede leerlo con `context.watch<AuthProvider>()`
/// (Ejercicio 7 del módulo: ChangeNotifier + Provider). Al cambiar
/// [status], el `AuthGate` redibuja la app completa: muestra el login o
/// la pantalla principal sin que nadie tenga que navegar "a mano".
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  Session? session;

  bool busy = false;
  String? errorMessage;

  /// Aviso informativo para el login (p. ej. "tu sesión expiró").
  String? notice;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  /// Al abrir la app: intenta recuperar la sesión guardada (persistencia de sesión).
  Future<void> restoreSession() async {
    try {
      final restored = await _service.restoreSession();
      if (restored == null) {
        status = AuthStatus.unauthenticated;
      } else {
        user = restored.user;
        session = restored.session;
        status = AuthStatus.authenticated;
      }
    } catch (_) {
      // Si el almacenamiento seguro falla, por seguridad se pide login de nuevo.
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    busy = true;
    errorMessage = null;
    notice = null;
    notifyListeners();

    try {
      final result = await _service.login(username: username, password: password);
      user = result.user;
      session = result.session;
      status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Crea la cuenta y, si sale bien, inicia sesión automáticamente.
  Future<bool> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    busy = true;
    errorMessage = null;
    notice = null;
    notifyListeners();

    try {
      await _service.register(
        username: username,
        displayName: displayName,
        password: password,
      );
      final result = await _service.login(username: username, password: password);
      user = result.user;
      session = result.session;
      status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = 'No se pudo crear la cuenta. Intenta de nuevo.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Cierra sesión: borra el token seguro y limpia el estado global.
  /// Los demás providers (p. ej. el GPS) reaccionan a este cambio.
  Future<void> logout({String? reason}) async {
    try {
      await _service.logout();
    } catch (_) {
      // Aunque falle el borrado del token, la sesión se cierra en memoria.
    } finally {
      user = null;
      session = null;
      errorMessage = null;
      notice = reason;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Se llama al volver a la app: si el token venció, se cierra la sesión.
  Future<void> validateSession() async {
    if (!isAuthenticated) return;
    final current = session;
    if (current == null || current.isExpired) {
      await logout(reason: 'Tu sesión expiró. Inicia sesión de nuevo.');
    }
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }
}
