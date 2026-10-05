// Pruebas del cálculo de horas trabajadas (lógica pura, sin interfaz).

import 'package:fichaje_app/models/place_info.dart';
import 'package:fichaje_app/models/punch.dart';
import 'package:fichaje_app/utils/formatters.dart';
import 'package:fichaje_app/utils/work_time.dart';
import 'package:flutter_test/flutter_test.dart';

Punch _punch(String id, PunchType type, DateTime time) => Punch(
      id: id,
      type: type,
      time: time,
      latitude: 6.2442,
      longitude: -75.5812,
      accuracy: 8,
    );

void main() {
  // Viernes 2 de octubre de 2026 (mismos datos de la imagen de ejemplo).
  final day = DateTime(2026, 10, 2);

  test('suma tramos cerrados y el tramo abierto hasta "ahora"', () {
    final punches = [
      _punch('1', PunchType.entrada, DateTime(2026, 10, 2, 7, 58)),
      _punch('2', PunchType.salida, DateTime(2026, 10, 2, 12, 15)), // 4 h 17 min
      _punch('3', PunchType.entrada, DateTime(2026, 10, 2, 13, 10)),
    ];
    final now = DateTime(2026, 10, 2, 14, 35); // 1 h 25 min más

    final worked = workedOn(day, buildSegments(punches), now);

    expect(worked, const Duration(hours: 5, minutes: 42));
    expect(formatDuration(worked), '5 h 42 min');
  });

  test('ignora una salida sin entrada y entradas repetidas', () {
    final punches = [
      _punch('1', PunchType.salida, DateTime(2026, 10, 2, 7, 0)),
      _punch('2', PunchType.entrada, DateTime(2026, 10, 2, 8, 0)),
      _punch('3', PunchType.entrada, DateTime(2026, 10, 2, 9, 0)),
      _punch('4', PunchType.salida, DateTime(2026, 10, 2, 10, 0)),
    ];

    final segments = buildSegments(punches);

    expect(segments.length, 1);
    expect(workedOn(day, segments, DateTime(2026, 10, 2, 18, 0)), const Duration(hours: 2));
  });

  test('un tramo que cruza la medianoche se reparte entre los dos días', () {
    final punches = [
      _punch('1', PunchType.entrada, DateTime(2026, 10, 1, 22, 0)),
      _punch('2', PunchType.salida, DateTime(2026, 10, 2, 2, 0)),
    ];
    final segments = buildSegments(punches);
    final now = DateTime(2026, 10, 2, 12, 0);

    expect(workedOn(DateTime(2026, 10, 1), segments, now), const Duration(hours: 2));
    expect(workedOn(DateTime(2026, 10, 2), segments, now), const Duration(hours: 2));
  });

  test('summarize agrupa por día y marca la jornada en curso', () {
    final punches = [
      _punch('1', PunchType.entrada, DateTime(2026, 10, 1, 8, 0)),
      _punch('2', PunchType.salida, DateTime(2026, 10, 1, 17, 0)),
      _punch('3', PunchType.entrada, DateTime(2026, 10, 2, 8, 0)),
    ];

    final days = summarize(punches, DateTime(2026, 10, 2, 10, 0));

    expect(days.length, 2);
    expect(days.first.day, DateTime(2026, 10, 2)); // el más reciente primero
    expect(days.first.inProgress, isTrue);
    expect(days.first.worked, const Duration(hours: 2));
    expect(days.last.inProgress, isFalse);
    expect(days.last.worked, const Duration(hours: 9));
  });

  test('Punch conserva el nombre del lugar al guardar y leer (JSON)', () {
    final named = Punch(
      id: '8',
      type: PunchType.entrada,
      time: DateTime(2026, 10, 2, 8, 0),
      latitude: 4.65,
      longitude: -74.06,
      accuracy: 12,
      place: const PlaceInfo(title: 'Chapinero', subtitle: 'Bogotá, Cundinamarca'),
    );
    expect(Punch.fromJson(named.toJson()).whereLabel, 'Chapinero, Bogotá, Cundinamarca');

    final original = Punch(
      id: '9',
      type: PunchType.salida,
      time: DateTime(2026, 10, 2, 17, 0),
      latitude: 4.65,
      longitude: -74.06,
      accuracy: 12,
    );
    final copy = Punch.fromJson(original.toJson());

    expect(copy.type, PunchType.salida);
    expect(copy.place, isNull);
    expect(copy.whereLabel, '4.65000, -74.06000'); // sin nombre → coordenadas
  });
}
