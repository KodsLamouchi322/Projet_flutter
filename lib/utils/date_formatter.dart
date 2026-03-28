// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  static String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'A l instant';
    if (diff.inHours < 1) return 'Il y a \ min';
    if (diff.inDays < 1) return 'Il y a \h';
    if (diff.inDays < 7) return 'Il y a \ jours';
    return formatDate(date);
  }
  static String formatDueDate(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inDays < 0) return 'Expire depuis \j';
    if (diff.inDays == 0) return 'Expire aujourd hui';
    return 'Dans \ jours';
  }
}
