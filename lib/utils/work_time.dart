import '../models/punch.dart';
import 'formatters.dart';

/// Un tramo de trabajo: desde una ENTRADA hasta su SALIDA.
/// Si todavía no hay salida, el tramo está abierto (la jornada sigue).
class WorkSegment {
  const WorkSegment({required this.entry, this.exit});

  final Punch entry;
  final Punch? exit;

  bool get isOpen => exit == null;

  DateTime get start => entry.time;

  /// Fin del tramo; si sigue abierto, termina "ahora".
  DateTime endAt(DateTime now) => exit?.time ?? now;
}

/// Empareja las marcaciones en tramos (entrada → salida).
/// Acepta la lista en cualquier orden. Salidas sin entrada previa y entradas
/// repetidas se ignoran, así los datos raros nunca rompen el cálculo.
List<WorkSegment> buildSegments(List<Punch> punches) {
  final sorted = [...punches]..sort((a, b) => a.time.compareTo(b.time));
  final segments = <WorkSegment>[];
  Punch? open;

  for (final punch in sorted) {
    if (punch.isEntry) {
      open ??= punch;
    } else if (open != null) {
      segments.add(WorkSegment(entry: open, exit: punch));
      open = null;
    }
  }
  if (open != null) segments.add(WorkSegment(entry: open));
  return segments;
}

/// Horas trabajadas dentro de un día calendario (recorta tramos que cruzan
/// la medianoche).
Duration workedOn(DateTime day, List<WorkSegment> segments, DateTime now) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = DateTime(day.year, day.month, day.day + 1);
  var total = Duration.zero;

  for (final segment in segments) {
    final start = segment.start.isBefore(dayStart) ? dayStart : segment.start;
    final rawEnd = segment.endAt(now);
    final end = rawEnd.isAfter(dayEnd) ? dayEnd : rawEnd;
    if (end.isAfter(start)) total += end.difference(start);
  }
  return total;
}

/// Resumen de un día: horas trabajadas y sus marcaciones.
class DaySummary {
  const DaySummary({
    required this.day,
    required this.worked,
    required this.punches,
    required this.inProgress,
  });

  final DateTime day;
  final Duration worked;

  /// Marcaciones del día, de la más reciente a la más antigua.
  final List<Punch> punches;

  /// `true` si ese día termina con una entrada sin salida (jornada abierta).
  final bool inProgress;

  Punch? get firstEntry {
    for (final p in punches.reversed) {
      if (p.isEntry) return p;
    }
    return null;
  }

  Punch? get lastExit {
    for (final p in punches) {
      if (!p.isEntry) return p;
    }
    return null;
  }
}

/// Agrupa todas las marcaciones por día (días recientes primero).
List<DaySummary> summarize(List<Punch> punches, DateTime now) {
  final segments = buildSegments(punches);
  final byDay = <DateTime, List<Punch>>{};

  for (final punch in punches) {
    final key = DateTime(punch.time.year, punch.time.month, punch.time.day);
    byDay.putIfAbsent(key, () => []).add(punch);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return days.map((day) {
    final list = byDay[day]!..sort((a, b) => b.time.compareTo(a.time));
    final openToday = segments.any(
      (s) => s.isOpen && isSameDay(s.start, day),
    );
    return DaySummary(
      day: day,
      worked: workedOn(day, segments, now),
      punches: list,
      inProgress: openToday,
    );
  }).toList();
}
