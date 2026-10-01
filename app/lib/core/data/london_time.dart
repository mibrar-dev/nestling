// Nestling — Europe/London display helpers.
//
// All timestamps are stored UTC (see AppDatabase). These pure functions
// convert to Europe/London for display, including BST (last Sunday of
// March 01:00 UTC → last Sunday of October 01:00 UTC).

/// True when [utc] falls inside UK daylight saving (BST = UTC+1).
bool isLondonSummerTime(DateTime utc) {
  final year = utc.year;
  final start = _lastSunday(year, 3).add(const Duration(hours: 1));
  final end = _lastSunday(year, 10).add(const Duration(hours: 1));
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Convert a UTC instant to wall-clock Europe/London time.
DateTime toLondon(DateTime utc) {
  final instant = utc.toUtc();
  return instant.add(Duration(hours: isLondonSummerTime(instant) ? 1 : 0));
}

DateTime _lastSunday(int year, int month) {
  // Last day of [month], then walk back to Sunday.
  final lastDay = DateTime.utc(year, month + 1, 0);
  final back = lastDay.weekday % 7; // Sunday == 7 → 0
  return DateTime.utc(year, month, lastDay.day - back);
}

const _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = <String>[
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

/// `Sat 4 Oct` for a UTC instant.
String formatLondonDay(DateTime utc) {
  final local = toLondon(utc);
  return '${_weekdays[local.weekday - 1]} ${local.day} '
      '${_months[local.month - 1]}';
}

/// `8:12am` for a UTC instant.
String formatLondonTime(DateTime utc) {
  final local = toLondon(utc);
  final suffix = local.hour < 12 ? 'am' : 'pm';
  var hour = local.hour % 12;
  if (hour == 0) hour = 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute$suffix';
}
