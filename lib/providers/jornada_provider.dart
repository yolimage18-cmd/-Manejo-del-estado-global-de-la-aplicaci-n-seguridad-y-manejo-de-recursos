import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/place_info.dart';
import '../models/punch.dart';
import '../services/place_service.dart';
import '../services/punch_storage.dart';
import '../utils/constants.dart';
import '../utils/work_time.dart';
import 'auth_provider.dart';

/// Resultado de una lectura de ubicación: coordenadas + nombre del lugar.
typedef LocationFix = ({Position position, PlaceInfo? place});

/// ESTADO GLOBAL #2: jornada del usuario (entradas/salidas) + recurso GPS.
///
/// Responsabilidades:
///  - Controla el PERMISO de ubicación (se consulta/solicita solo cuando
///    el usuario lo necesita, y se vuelve a pedir en cada sesión nueva).
///  - Obtiene la ubicación UNA sola vez por marcación (sin que el usuario
///    se mueva) y la convierte en un NOMBRE DE LUGAR (ciudad, barrio, sitio).
///  - MANEJO DE RECURSOS: escucha al [AuthProvider]; en el instante en
///    que se cierra sesión (o cambia de usuario) descarta cualquier lectura
///    de GPS pendiente, borra de memoria la ubicación y el permiso aprobado
///    y limpia los datos del usuario anterior.
class JornadaProvider extends ChangeNotifier {
  JornadaProvider({
    required AuthProvider auth,
    required PunchStorage storage,
    required PlaceService placeService,
  })  : _auth = auth,
        _storage = storage,
        _places = placeService {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthProvider _auth;
  final PunchStorage _storage;
  final PlaceService _places;

  String? _userId;

  // Contador de sesiones: cambia cada vez que se inicia o cierra sesión. Sirve
  // para descartar resultados atrasados (lecturas de GPS o del historial) que
  // pertenecen a una sesión anterior, aunque sea el mismo usuario.
  int _epoch = 0;

  // Último punto para el que se consultó el nombre del lugar (evita repetir
  // la consulta si el usuario casi no se movió).
  Position? _placePosition;

  // Cola de guardado: las escrituras se hacen una tras otra y, al cerrar
  // sesión, se espera a que terminen (así nunca se pierde una marcación).
  Future<void> _saving = Future<void>.value();

  // ---------------- Estado observable por la UI ----------------

  /// Marcaciones del usuario, la más reciente primero.
  List<Punch> punches = [];

  /// `true` cuando el historial del usuario ya se leyó del dispositivo.
  /// Mientras es `false`, los botones Entrada/Salida esperan (así no se
  /// muestra un estado equivocado justo después de iniciar sesión).
  bool punchesLoaded = false;

  PermissionStatus? permission;
  Position? lastPosition;
  DateTime? lastPositionAt; // hora en que se recibió la última lectura
  PlaceInfo? lastPlace; // nombre del lugar de la última lectura
  bool isLocating = false;
  String? message;

  /// ¿El usuario ya aceptó el aviso de ubicación EN ESTA SESIÓN? Se borra al
  /// cerrar sesión (o al cerrar la app), así el permiso se vuelve a pedir
  /// cada vez que se ingresa de nuevo.
  bool locationApprovedThisSession = false;

  bool get hasPermission => permission?.isGranted ?? false;

  // ---------------- Jornada ----------------

  /// Última marcación según la HORA (no según la posición en la lista).
  Punch? get lastPunch {
    if (punches.isEmpty) return null;
    var latest = punches.first;
    for (final p in punches) {
      if (p.time.isAfter(latest.time)) latest = p;
    }
    return latest;
  }

  /// ¿Hay una jornada abierta? (la última marcación fue una entrada)
  bool get isWorking => lastPunch?.isEntry ?? false;

  /// Hora de la entrada de la jornada en curso.
  DateTime? get workingSince => isWorking ? lastPunch!.time : null;

  List<WorkSegment> get segments => buildSegments(punches);

  /// Horas trabajadas hoy (si la jornada sigue abierta, cuenta hasta ahora).
  Duration workedToday([DateTime? now]) {
    final current = now ?? DateTime.now();
    return workedOn(current, segments, current);
  }

  /// Marcaciones de hoy, de la más reciente a la más antigua.
  List<Punch> todayPunches([DateTime? now]) {
    final current = now ?? DateTime.now();
    return punches
        .where((p) =>
            p.time.year == current.year &&
            p.time.month == current.month &&
            p.time.day == current.day)
        .toList();
  }

  // ---------------- Reacción al cambio de sesión ----------------

  void _onAuthChanged() {
    final newId = _auth.isAuthenticated ? _auth.user!.id : null;
    if (newId == _userId) return;

    _userId = newId;
    _epoch++;

    // Sesión cerrada o usuario distinto: se libera todo lo relacionado con
    // la ubicación y se borran de memoria los datos del usuario anterior.
    lastPosition = null;
    lastPositionAt = null;
    lastPlace = null;
    _placePosition = null;
    permission = null;
    locationApprovedThisSession = false; // el permiso se vuelve a pedir
    isLocating = false; // una lectura pendiente se descarta
    message = null;
    punches = [];
    punchesLoaded = false;
    notifyListeners();

    if (newId != null) _loadPunches(newId);
  }

  Future<void> _loadPunches(String userId) async {
    final epoch = _epoch;

    // Se espera a que termine cualquier guardado pendiente antes de leer.
    await _saving;

    List<Punch> loaded = [];
    var failed = false;
    try {
      loaded = await _storage.load(userId);
    } catch (_) {
      failed = true;
    }
    if (_epoch != epoch) return; // la sesión cambió mientras se leía

    if (failed) {
      // No se marca como cargado: así no se sobrescribe el historial real.
      message = 'No se pudo leer tu historial. Cierra sesión e intenta de nuevo.';
      notifyListeners();
      return;
    }

    loaded.sort((a, b) => b.time.compareTo(a.time));
    punches = loaded;
    punchesLoaded = true;
    notifyListeners();
  }

  /// Guarda en el dispositivo (en cola, una escritura a la vez).
  Future<void> _persist(String userId, List<Punch> snapshot) {
    _saving = _saving.then((_) async {
      try {
        await _storage.save(userId, snapshot);
      } catch (_) {
        if (_userId == userId) {
          message = 'No se pudo guardar el registro en el dispositivo.';
          notifyListeners();
        }
      }
    });
    return _saving;
  }

  /// Espera a que termine cualquier guardado pendiente (se usa al cerrar sesión).
  Future<void> flushPending() => _saving;

  // ---------------- Permisos ----------------

  /// Consulta el estado actual SIN mostrar ningún diálogo del sistema.
  Future<PermissionStatus> refreshPermission() async {
    permission = await Permission.locationWhenInUse.status;
    notifyListeners();
    return permission!;
  }

  /// Muestra el diálogo del sistema pidiendo el permiso.
  Future<PermissionStatus> requestPermission() async {
    permission = await Permission.locationWhenInUse.request();
    notifyListeners();
    return permission!;
  }

  /// Marca que el usuario ya aceptó el aviso de ubicación en esta sesión.
  void approveLocationThisSession() {
    if (_userId == null) return; // sin sesión no se aprueba nada
    locationApprovedThisSession = true;
  }

  // ---------------- Nombre del lugar ----------------

  /// Devuelve el nombre del lugar de [position]. Si el usuario casi no se
  /// movió desde la última consulta, reutiliza el nombre anterior (ahorra
  /// datos y batería).
  Future<PlaceInfo?> _placeFor(Position position) async {
    final previous = _placePosition;
    if (previous != null && lastPlace != null) {
      final moved = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      if (moved < 30) return lastPlace;
    }
    final place = await _places.resolve(position.latitude, position.longitude);
    _placePosition = position;
    return place;
  }

  // ---------------- Ubicación puntual (no hace falta moverse) ----------------

  /// Obtiene UNA ubicación (más el nombre del lugar) y deja de usar el GPS.
  /// Es lo que usan los botones "Entrada" y "Salida".
  Future<LocationFix?> locateOnce() async {
    if (isLocating) return null;
    final epoch = _epoch;

    isLocating = true;
    message = null;
    notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        message = 'El GPS del dispositivo está apagado. Actívalo e intenta de nuevo.';
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: kLocationTimeout,
        ),
      );
      if (_epoch != epoch) return null; // se cerró la sesión mientras tanto

      lastPosition = position;
      lastPositionAt = DateTime.now();
      notifyListeners(); // se muestra la lectura mientras se busca el nombre

      final place = await _placeFor(position);
      if (_epoch != epoch) return null;

      lastPlace = place;
      return (position: position, place: place);
    } on TimeoutException {
      message = 'No se pudo obtener la ubicación a tiempo. Si usas el emulador, '
          'fija un punto en Extended controls → Location.';
      return null;
    } on PermissionDeniedException {
      message = 'No hay permiso de ubicación. Concédelo para continuar.';
      return null;
    } on LocationServiceDisabledException {
      message = 'El GPS del dispositivo está apagado. Actívalo e intenta de nuevo.';
      return null;
    } catch (e) {
      message = 'No se pudo obtener la ubicación: $e';
      return null;
    } finally {
      if (_epoch == epoch) isLocating = false;
      notifyListeners();
    }
  }

  // ---------------- Marcaciones ----------------

  /// Registra una ENTRADA o una SALIDA con la hora actual y el lugar.
  Future<Punch?> registerPunch(PunchType type) async {
    final userId = _userId;
    if (userId == null || isLocating) return null;

    if (!punchesLoaded) {
      message = 'Espera un momento: se está cargando tu historial.';
      notifyListeners();
      return null;
    }
    if (type == PunchType.entrada && isWorking) {
      message = 'Ya marcaste tu entrada. Marca la salida para cerrar la jornada.';
      notifyListeners();
      return null;
    }
    if (type == PunchType.salida && !isWorking) {
      message = 'Primero marca tu entrada para poder registrar la salida.';
      notifyListeners();
      return null;
    }

    final epoch = _epoch;
    final tappedAt = DateTime.now();
    final fix = await locateOnce();
    if (fix == null || _epoch != epoch) return null;

    final item = Punch(
      id: tappedAt.microsecondsSinceEpoch.toString(),
      type: type,
      time: tappedAt,
      latitude: fix.position.latitude,
      longitude: fix.position.longitude,
      accuracy: fix.position.accuracy,
      place: fix.place,
    );

    // Se limita el historial para cuidar almacenamiento y memoria.
    final updated = [item, ...punches];
    punches = updated.length > kMaxPunches ? updated.sublist(0, kMaxPunches) : updated;

    notifyListeners(); // la UI se actualiza de inmediato...
    await _persist(userId, punches); // ...y se guarda en disco
    return item;
  }

  Future<void> deletePunch(String id) async {
    final userId = _userId;
    if (userId == null) return;
    punches = punches.where((p) => p.id != id).toList();
    notifyListeners();
    await _persist(userId, punches);
  }

  Future<void> clearHistory() async {
    final userId = _userId;
    if (userId == null) return;
    punches = [];
    notifyListeners();
    await _persist(userId, punches);
  }

  void clearMessage() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }

  // ---------------- Limpieza ----------------

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _places.dispose();
    super.dispose();
  }
}
