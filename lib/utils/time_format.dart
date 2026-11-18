import 'package:intl/intl.dart';

/// Formatea una fecha como texto relativo ("hace 2 min", "ahora mismo").
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(time);

  if (difference.isNegative || difference.inSeconds < 10) {
    return 'ahora mismo';
  }
  if (difference.inSeconds < 60) {
    return 'hace ${difference.inSeconds} s';
  }
  if (difference.inMinutes < 60) {
    return 'hace ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'hace ${difference.inHours} h';
  }
  if (difference.inDays == 1) {
    return 'ayer';
  }
  if (difference.inDays < 7) {
    return 'hace ${difference.inDays} días';
  }
  return 'hace ${(difference.inDays / 7).floor()} semanas';
}

/// Hora del día en formato `HH:mm:ss`.
String formatClock(DateTime time) => DateFormat('HH:mm:ss').format(time);

/// Fecha y hora completas en formato `dd/MM/yyyy HH:mm:ss`.
String formatDateTime(DateTime time) =>
    DateFormat('dd/MM/yyyy HH:mm:ss').format(time);

/// Fecha y hora resumidas en formato `dd/MM HH:mm`.
String formatShortDateTime(DateTime time) =>
    DateFormat('dd/MM HH:mm').format(time);
