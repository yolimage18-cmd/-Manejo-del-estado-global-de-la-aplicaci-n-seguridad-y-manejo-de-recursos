import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/punch.dart';
import '../utils/constants.dart';

/// Historial de marcaciones de cada usuario.
///
/// Se guarda en SharedPreferences (Ejercicio 9 del módulo) porque NO es
/// información de credenciales; lo sensible (token y contraseña) vive en
/// SecureStore. Cada usuario tiene su propia clave, así que los datos de
/// una cuenta no se mezclan con los de otra en el mismo dispositivo.
class PunchStorage {
  Future<List<Punch>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(punchesKeyFor(userId));
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Punch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return []; // dato dañado: se ignora en vez de romper la app
    }
  }

  Future<void> save(String userId, List<Punch> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((p) => p.toJson()).toList());
    await prefs.setString(punchesKeyFor(userId), encoded);
  }
}
