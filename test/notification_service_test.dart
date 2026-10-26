import 'package:flutter_test/flutter_test.dart';
import 'package:habit_garden/core/notification_payload.dart';

void main() {
  group('habitIdFromNotificationPayload', () {
    test('extracts a positive habit id', () {
      expect(habitIdFromNotificationPayload('habit:42'), 42);
      expect(habitIdFromNotificationPayload('habit:42:2026-10-22'), 42);
    });

    test('rejects malformed payloads', () {
      expect(habitIdFromNotificationPayload(null), isNull);
      expect(habitIdFromNotificationPayload('habit:'), isNull);
      expect(habitIdFromNotificationPayload('habit:0'), isNull);
      expect(habitIdFromNotificationPayload('other:42'), isNull);
      expect(habitIdFromNotificationPayload('habit:42:extra'), isNull);
    });
  });

  group('dated notification payload', () {
    test('round-trips habit id and date', () {
      final payload = habitNotificationPayload(7, DateTime(2026, 10, 22));

      expect(payload, 'habit:7:2026-10-22');
      expect(habitIdFromNotificationPayload(payload), 7);
      expect(dateFromNotificationPayload(payload), DateTime(2026, 10, 22));
    });

    test('rejects an invalid date', () {
      expect(dateFromNotificationPayload('habit:7:2026-99-99'), isNull);
      expect(habitIdFromNotificationPayload('habit:7:2026-99-99'), isNull);
    });
  });
}
