import 'package:app/core/utils/weekdays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weekdays', () {
    test('the week starts on Saturday and has seven days', () {
      expect(weekOrder, <int>[6, 7, 1, 2, 3, 4, 5]);
      expect(allWeekdays, {1, 2, 3, 4, 5, 6, 7});
    });

    test('every day is only the full week', () {
      expect(isEveryDay(allWeekdays), isTrue);
      expect(isEveryDay(<int>[1, 2, 3, 4, 5, 6]), isFalse);
      expect(isEveryDay(const <int>[]), isFalse);
    });

    test('a tap on a day with the full week picks that day alone', () {
      expect(toggleWeekday(allWeekdays, 3), <int>{3});
    });

    test('a tap adds a missing day and removes a chosen one', () {
      expect(toggleWeekday(<int>{1, 7}, 3), <int>{1, 3, 7});
      expect(toggleWeekday(<int>{1, 7}, 7), <int>{1});
    });

    test('the last day can be removed, leaving the week empty', () {
      expect(toggleWeekday(<int>{4}, 4), isEmpty);
    });

    test('a tap never changes the set it was given', () {
      final Set<int> before = <int>{1, 2};
      toggleWeekday(before, 3);
      expect(before, <int>{1, 2});
    });
  });
}
