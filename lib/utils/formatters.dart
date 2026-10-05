import 'package:intl/intl.dart';

final DateFormat _timeFormat = DateFormat('h:mm a');

const List<String> _weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const List<String> _weekdayLong = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const List<String> _monthShort = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Hora legible: "1:10 PM".
String formatTime(DateTime date) => _timeFormat.format(date);

/// Día de la semana abreviado: "Vie".
String weekdayShort(DateTime date) => _weekdayShort[date.weekday - 1];

/// Día de la semana completo: "Viernes".
String weekdayLong(DateTime date) => _weekdayLong[date.weekday - 1];

/// Fecha corta: "2 oct".
String formatDayMonth(DateTime date) => '${date.day} ${_monthShort[date.month - 1]}';

/// Fecha y hora: "2 oct, 1:10 PM".
String formatDateTime(DateTime date) => '${formatDayMonth(date)}, ${formatTime(date)}';

/// Muestra solo la hora si es de hoy; si no, agrega la fecha.
String describeMoment(DateTime moment, DateTime now) =>
    isSameDay(moment, now) ? formatTime(moment) : formatDateTime(moment);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Duración legible: "5 h 42 min".
String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes < 0 ? 0 : duration.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$hours h $minutes min';
}

/// Coordenada con 5 decimales (solo se usa si no hay nombre de lugar).
String formatCoord(double value) => value.toStringAsFixed(5);

/// Distancia legible: "35 m" o "1.2 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
