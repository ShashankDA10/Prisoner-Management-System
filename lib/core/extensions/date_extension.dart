import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

extension DateTimeExtension on DateTime {
  String get displayDate =>
      DateFormat(AppConstants.dateDisplayFormat).format(this);

  String get displayDateTime =>
      DateFormat(AppConstants.dateTimeFormat).format(this);

  String get isoDate =>
      DateFormat(AppConstants.dateIso).format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek   = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
}

extension StringDateExtension on String {
  DateTime? tryParseDate() {
    try {
      return DateFormat(AppConstants.dateDisplayFormat).parse(this);
    } catch (_) {
      try {
        return DateTime.parse(this);
      } catch (_) {
        return null;
      }
    }
  }
}
