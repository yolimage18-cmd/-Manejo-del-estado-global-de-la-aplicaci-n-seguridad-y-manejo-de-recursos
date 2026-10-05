import 'dart:convert';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;

import '../models/place_info.dart';
import '../utils/constants.dart';

/// Convierte coordenadas (latitud/longitud) en un NOMBRE DE LUGAR legible:
/// barrio, calle o sitio + ciudad.
///
/// Estrategia (la primera que funcione):
///  1. Geocodificador del propio dispositivo (paquete `geocoding`).
///  2. Respaldo: servicio público de OpenStreetMap (Nominatim) por HTTP.
///  3. Si ambos fallan (p. ej. sin internet) devuelve `null` y la interfaz
///     muestra las coordenadas como último recurso.
class PlaceService {
  PlaceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 8);

  Future<PlaceInfo?> resolve(double latitude, double longitude) async {
    final fromDevice = await _fromDevice(latitude, longitude);
    if (fromDevice != null) return fromDevice;
    return _fromNominatim(latitude, longitude);
  }

  // ---------------- 1. Geocodificador del dispositivo ----------------

  Future<PlaceInfo?> _fromDevice(double latitude, double longitude) async {
    try {
      final marks = await geo
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(_timeout);
      for (final mark in marks) {
        final place = _compose(
          landmark: mark.name,
          street: mark.thoroughfare ?? mark.street,
          neighborhood: mark.subLocality,
          city: mark.locality ?? mark.subAdministrativeArea,
          region: mark.administrativeArea,
          country: mark.country,
        );
        if (place != null) return place;
      }
    } catch (_) {
      // Sin geocodificador o sin internet: se prueba el respaldo.
    }
    return null;
  }

  // ---------------- 2. Respaldo: OpenStreetMap (Nominatim) ----------------

  Future<PlaceInfo?> _fromNominatim(double latitude, double longitude) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'es',
      });

      final response = await _client
          .get(uri, headers: {'User-Agent': kPlaceUserAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final address = data['address'];
      final a = address is Map<String, dynamic> ? address : <String, dynamic>{};

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = a[key];
          if (value is String && value.trim().isNotEmpty) return value;
        }
        return null;
      }

      return _compose(
        landmark: data['name'] as String?,
        street: pick(['road', 'pedestrian', 'footway']),
        neighborhood: pick(['neighbourhood', 'suburb', 'quarter', 'city_district']),
        city: pick(['city', 'town', 'village', 'municipality', 'county']),
        region: pick(['state', 'region']),
        country: pick(['country']),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------- Armado del texto ----------------

  /// Elige el título más útil (nombre del sitio > barrio > calle > ciudad)
  /// y un subtítulo con la ciudad y la región.
  PlaceInfo? _compose({
    String? landmark,
    String? street,
    String? neighborhood,
    String? city,
    String? region,
    String? country,
  }) {
    final lm = _clean(landmark);
    final st = _clean(street);
    final nb = _clean(neighborhood);
    final ct = _clean(city);
    final rg = _clean(region);
    final cn = _clean(country);

    // Un "nombre" que solo es la calle repetida o un número no sirve de título.
    final landmarkIsUseful = lm != null && lm != st && !RegExp(r'^\d+$').hasMatch(lm);

    final title = (landmarkIsUseful ? lm : null) ?? nb ?? st ?? ct ?? rg ?? cn;
    if (title == null) return null;

    final parts = <String>[];
    for (final candidate in [ct, rg ?? cn]) {
      if (candidate != null && candidate != title && !parts.contains(candidate)) {
        parts.add(candidate);
      }
    }
    // Si hay barrio y el título es otra cosa, el barrio aporta contexto.
    if (nb != null && nb != title && !parts.contains(nb)) parts.insert(0, nb);

    return PlaceInfo(title: title, subtitle: parts.take(2).join(', '));
  }

  /// Limpia el texto; descarta vacíos y los "Plus Codes" (p. ej. "5RJ4+X8").
  String? _clean(String? value) {
    if (value == null) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    if (RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}').hasMatch(text)) return null;
    return text;
  }

  void dispose() => _client.close();
}
