import 'package:app/core/utils/history_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryFilter', () {
    final DateTime morning = DateTime(2026, 11, 9, 8);

    test('everything shows with no filter', () {
      expect(HistoryFilter.all.shows(morning, (null, null)), isTrue);
    });

    test('one day keeps that day only, whatever the hour', () {
      final HistoryFilter filter = HistoryFilter.all.withDay(
        DateTime(2026, 11, 9),
      );

      expect(filter.shows(morning, ('a-1', 'لينا')), isTrue);
      expect(filter.shows(DateTime(2026, 11, 10, 8), ('a-1', 'لينا')), isFalse);
    });

    test('one person keeps what they recorded, by account or name', () {
      final HistoryFilter filter = HistoryFilter.all.withPerson('a-1');

      expect(filter.shows(morning, ('a-1', 'لينا')), isTrue);
      expect(filter.shows(morning, ('a-2', 'سارة')), isFalse);
      expect(filter.shows(morning, (null, null)), isFalse);
      expect(
        HistoryFilter.all.withPerson('سارة').shows(morning, (null, 'سارة')),
        isTrue,
      );
    });

    test('lists each day once, newest first, and each person once', () {
      expect(
        HistoryFilter.daysOf(<DateTime>[
          morning,
          DateTime(2026, 11, 10, 9),
          DateTime(2026, 11, 9, 20),
        ]),
        <DateTime>[DateTime(2026, 11, 10), DateTime(2026, 11, 9)],
      );
      expect(
        HistoryFilter.peopleOf(<(String?, String?)>[
          ('a-1', 'لينا'),
          ('a-1', 'لينا'),
          (null, 'سارة'),
          (null, null),
        ]),
        <String, String>{'a-1': 'لينا', 'سارة': 'سارة'},
      );
    });

    test('drops a day or a person another month does not have', () {
      final HistoryFilter filter = HistoryFilter(
        day: DateTime(2026, 10, 3),
        person: 'a-9',
      );

      expect(
        filter.within(
          <DateTime>[DateTime(2026, 11, 9)],
          <String, String>{'a-1': 'لينا'},
        ),
        HistoryFilter.all,
      );
      expect(
        filter.within(
          <DateTime>[DateTime(2026, 10, 3)],
          <String, String>{'a-9': 'سارة'},
        ),
        filter,
      );
    });
  });
}
