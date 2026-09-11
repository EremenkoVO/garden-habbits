DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String dateKey(DateTime value) {
  final date = dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime dateFromKey(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

Iterable<DateTime> daysBetween(DateTime start, DateTime end) sync* {
  var cursor = dateOnly(start);
  final last = dateOnly(end);
  while (!cursor.isAfter(last)) {
    yield cursor;
    cursor = cursor.add(const Duration(days: 1));
  }
}
