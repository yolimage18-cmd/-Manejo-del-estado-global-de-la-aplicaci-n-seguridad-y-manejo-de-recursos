/// Usuario autenticado. Nunca contiene la contraseña: solo datos de perfil.
class AppUser {
  final String id;
  final String username;
  final String displayName;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  /// Inicial para el avatar.
  String get initial =>
      displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();

  /// Primer nombre para el saludo ("Hola, Yolima").
  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? username : parts.first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
