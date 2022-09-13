import 'package:flutter_test/flutter_test.dart';
import 'package:very_good_infinite_list/src/callback_debouncer.dart';

void main() {
  group('CallbackDebouncer', () {
    test('calls callback after specified duration expires', () async {
      const duration = Duration(milliseconds: 250);

      var callCount = 0;

      CallbackDebouncer(duration)(() => callCount++);

      expect(callCount, equals(0));

      await Future<void>.delayed(duration);
      expect(callCount, equals(1));
    });

    test('immediately calls callback if specified duration is zero', () async {
      var callCount = 0;

      CallbackDebouncer(Duration.zero)(() => callCount++);

      expect(callCount, equals(1));
    });
  });
}
