/// Constantes globales de la app "Fichaje".

const String kAppName = 'Fichaje';

// ---------------- Seguridad ----------------

/// Cuánto dura una sesión antes de pedir login otra vez.
const Duration kSessionDuration = Duration(hours: 24);

/// Vueltas de hash SHA-256 aplicadas a la contraseña (dificulta fuerza bruta).
const int kHashIterations = 5000;

/// Claves del almacenamiento SEGURO (cifrado). Aquí viven credenciales y token.
const String kUsersKey = 'fichaje_users';
const String kSessionKey = 'fichaje_session';

// ---------------- Jornada ----------------

/// Meta diaria de horas (el anillo de la pantalla principal se llena hasta aquí).
const Duration kDailyGoal = Duration(hours: 8);

// ---------------- Recursos (memoria / batería / almacenamiento) ----------------

/// Máximo de marcaciones guardadas por usuario (cuida almacenamiento y memoria).
const int kMaxPunches = 300;

/// Tiempo máximo para obtener una ubicación antes de rendirse.
const Duration kLocationTimeout = Duration(seconds: 20);

/// Identificación requerida por el servicio público de OpenStreetMap (Nominatim).
const String kPlaceUserAgent = 'FichajeJornadaApp/1.0 (tarea universitaria)';

/// Clave (por usuario) del historial en SharedPreferences (datos NO sensibles).
String punchesKeyFor(String userId) => 'fichaje_punches_$userId';
