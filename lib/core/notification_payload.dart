import 'date_utils.dart';

String habitNotificationPayload(int habitId, DateTime date) =>
    'habit:$habitId:${dateKey(date)}';

final _payloadPattern = RegExp(
  r'^habit:([1-9][0-9]*)(?::([0-9]{4}-[0-9]{2}-[0-9]{2}))?$',
);

DateTime? dateFromNotificationPayload(String? payload) {
  final match = _payloadPattern.firstMatch(payload ?? '');
  final key = match?.group(2);
  if (key == null) return null;
  final date = DateTime.tryParse(key);
  // DateTime normalizes invalid days and months; require an exact round trip.
  return date != null && dateKey(date) == key ? date : null;
}

int? habitIdFromNotificationPayload(String? payload) {
  final match = _payloadPattern.firstMatch(payload ?? '');
  if (match == null) return null;
  if (match.group(2) != null && dateFromNotificationPayload(payload) == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}
