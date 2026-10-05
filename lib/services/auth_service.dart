import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import '../utils/constants.dart';
import 'secure_store.dart';

/// Error "amigable" para mostrar en pantalla.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Sesión activa: token + dueño + fecha de vencimiento.
class Session {
  final String token;
  final String userId;
  final DateTime expiresAt;

  const Session({
    required this.token,
    required this.userId,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token'] as String,
        userId: json['userId'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

/// Autenticación 100 % local (el profesor indicó que no se necesita backend).
///
/// Seguridad aplicada:
///  1. La contraseña NUNCA se guarda: se guarda un hash SHA-256 con "sal"
///     aleatoria y varias iteraciones.
///  2. Todo (usuarios, hash y token de sesión) se guarda en [SecureStore],
///     que está cifrado por el sistema operativo.
///  3. El token de sesión es aleatorio (32 bytes de Random.secure) y vence
///     a las 24 horas.
class AuthService {
  AuthService(this._store);

  final SecureStore _store;
  static final Random _random = Random.secure();

  // ---------------- Registro ----------------

  Future<AppUser> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final users = await _loadUsers();
    final key = username.trim().toLowerCase();

    if (users.containsKey(key)) {
      throw const AuthException('Ese usuario ya existe. Elige otro nombre de usuario.');
    }

    final salt = _randomBytes(16);
    final user = AppUser(
      id: base64UrlEncode(_randomBytes(9)),
      username: key,
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );

    users[key] = {
      ...user.toJson(),
      'salt': base64Encode(salt),
      'hash': _hashPassword(password, salt),
    };
    await _saveUsers(users);
    return user;
  }

  // ---------------- Login ----------------

  Future<({AppUser user, Session session})> login({
    required String username,
    required String password,
  }) async {
    const invalid = AuthException('Usuario o contraseña incorrectos.');

    final users = await _loadUsers();
    final record = users[username.trim().toLowerCase()] as Map<String, dynamic>?;
    if (record == null) throw invalid;

    final salt = base64Decode(record['salt'] as String);
    final candidate = _hashPassword(password, salt);
    if (!_safeEquals(candidate, record['hash'] as String)) throw invalid;

    final user = AppUser.fromJson(record);
    final session = Session(
      token: base64UrlEncode(_randomBytes(32)),
      userId: user.id,
      expiresAt: DateTime.now().add(kSessionDuration),
    );

    // El token se guarda en el almacenamiento SEGURO.
    await _store.write(kSessionKey, jsonEncode(session.toJson()));
    return (user: user, session: session);
  }

  // ---------------- Persistencia de sesión ----------------

  /// Lee el token guardado. Devuelve null si no hay sesión o ya venció.
  Future<({AppUser user, Session session})?> restoreSession() async {
    final raw = await _store.read(kSessionKey);
    if (raw == null) return null;

    final session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (session.isExpired) {
      await logout();
      return null;
    }

    final users = await _loadUsers();
    for (final value in users.values) {
      final record = value as Map<String, dynamic>;
      if (record['id'] == session.userId) {
        return (user: AppUser.fromJson(record), session: session);
      }
    }

    // El token apunta a un usuario que ya no existe: se descarta.
    await logout();
    return null;
  }

  /// Cierra sesión: borra el token del almacenamiento seguro.
  Future<void> logout() => _store.delete(kSessionKey);

  // ---------------- Utilidades privadas ----------------

  Future<Map<String, dynamic>> _loadUsers() async {
    final raw = await _store.read(kUsersKey);
    if (raw == null) return <String, dynamic>{};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveUsers(Map<String, dynamic> users) =>
      _store.write(kUsersKey, jsonEncode(users));

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  /// SHA-256(sal + contraseña) repetido [kHashIterations] veces.
  String _hashPassword(String password, List<int> salt) {
    var digest = sha256.convert([...salt, ...utf8.encode(password)]).bytes;
    for (var i = 0; i < kHashIterations; i++) {
      digest = sha256.convert([...digest, ...salt]).bytes;
    }
    return base64Encode(digest);
  }

  /// Comparación en tiempo constante (evita ataques por tiempo de respuesta).
  bool _safeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
