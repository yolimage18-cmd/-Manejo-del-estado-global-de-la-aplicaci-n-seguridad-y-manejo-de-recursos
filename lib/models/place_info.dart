/// Nombre legible de un lugar (en vez de coordenadas).
///
/// Ejemplo: title = "Chapinero", subtitle = "Bogotá, Cundinamarca".
class PlaceInfo {
  const PlaceInfo({required this.title, this.subtitle = ''});

  /// Nombre principal: lugar, calle o barrio.
  final String title;

  /// Detalle: ciudad y departamento / país.
  final String subtitle;

  /// Texto en una sola línea: "Chapinero, Bogotá".
  String get label => subtitle.isEmpty ? title : '$title, $subtitle';

  Map<String, dynamic> toJson() => {'title': title, 'subtitle': subtitle};

  factory PlaceInfo.fromJson(Map<String, dynamic> json) => PlaceInfo(
        title: (json['title'] as String?) ?? '',
        subtitle: (json['subtitle'] as String?) ?? '',
      );
}
