import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Envoltorio del almacenamiento SEGURO del dispositivo.
///
/// REQUISITO DE SEGURIDAD (Tarea 02): el token de sesión y las credenciales
/// NO se guardan en SharedPreferences (texto plano), sino aquí:
///   - Android: EncryptedSharedPreferences (AES) con llave en el Android Keystore.
///   - iOS: Keychain.
class SecureStore {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Si el Keystore se corrompe (p. ej. al restaurar un respaldo), se
      // reinicia el almacén en vez de dejar la app sin poder abrir.
      resetOnError: true,
    ),
  );

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);
}
