import 'package:flutter_test/flutter_test.dart';
import 'package:habit_garden/services/notification_service.dart';

void main() {
  group('habitIdFromNotificationPayload', () {
    test('extracts a positive habit id', () {
      expect(habitIdFromNotificationPayload('habit:42'), 42);
    });

    test('rejects malformed payloads', () {
      expect(habitIdFromNotificationPayload(null), isNull);
      expect(habitIdFromNotificationPayload('habit:'), isNull);
      expect(habitIdFromNotificationPayload('habit:0'), isNull);
      expect(habitIdFromNotificationPayload('other:42'), isNull);
      expect(habitIdFromNotificationPayload('habit:42:extra'), isNull);
    });
  });
}
