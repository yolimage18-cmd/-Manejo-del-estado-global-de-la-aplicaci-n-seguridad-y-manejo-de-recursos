import '../utils/formatters.dart';
import 'place_info.dart';

/// Tipo de marcación de la jornada.
enum PunchType { entrada, salida }

/// Una marcación (fichaje): entrada o salida con hora y lugar.
class Punch {
  const Punch({
    required this.id,
    required this.type,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.place,
  });

  final String id;
  final PunchType type;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double accuracy;

  /// Nombre del lugar (ciudad, barrio, sitio). Es `null` si no se pudo
  /// obtener (por ejemplo, sin internet); en ese caso se muestran coordenadas.
  final PlaceInfo? place;

  bool get isEntry => type == PunchType.entrada;

  String get typeLabel => isEntry ? 'Entrada' : 'Salida';

  /// Lugar legible. Solo si no hay nombre se recurre a las coordenadas.
  String get whereLabel {
    final name = place?.label ?? '';
    if (name.isNotEmpty) return name;
    return '${formatCoord(latitude)}, ${formatCoord(longitude)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'time': time.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'place': place?.toJson(),
      };

  factory Punch.fromJson(Map<String, dynamic> json) {
    final placeJson = json['place'];
    return Punch(
      id: json['id'] as String,
      type: json['type'] == 'salida' ? PunchType.salida : PunchType.entrada,
      time: DateTime.parse(json['time'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: ((json['accuracy'] as num?) ?? 0).toDouble(),
      place: placeJson is Map<String, dynamic> ? PlaceInfo.fromJson(placeJson) : null,
    );
  }
}
