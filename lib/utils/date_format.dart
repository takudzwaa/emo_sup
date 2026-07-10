/// Lightweight date/time labels without extra packages.
class AppDateFormat {
  AppDateFormat._();

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

  static String monthShort(DateTime d) => _months[d.month - 1];

  /// e.g. "Wed, Jul 9"
  static String dayHeading(DateTime d) {
    return '${weekdayShort(d)}, ${monthShort(d)} ${d.day}';
  }

  /// e.g. "Jul 9, 2026"
  static String mediumDate(DateTime d) {
    return '${monthShort(d)} ${d.day}, ${d.year}';
  }

  /// e.g. "2:00 PM"
  static String timeOfDay(DateTime d) {
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

  /// e.g. "Wed, Jul 9 · 2:00 PM"
  static String slotLabel(DateTime d) {
    return '${dayHeading(d)} · ${timeOfDay(d)}';
  }
}
