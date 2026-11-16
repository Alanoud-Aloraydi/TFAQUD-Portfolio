import 'package:app/core/utils/history_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryFilter', () {
    final DateTime morning = DateTime(2026, 11, 9, 8);

    test('everything shows with no filter', () {
      expect(HistoryFilter.all.shows(morning, (null, null)), isTrue);
    });

    test('one month keeps that month only, whatever the day or hour', () {
      final HistoryFilter filter = HistoryFilter.all.withMonth(
        DateTime(2026, 11),
      );

      expect(filter.shows(morning, ('a-1', 'لينا')), isTrue);
      expect(filter.shows(DateTime(2026, 11, 30, 23), ('a-1', 'لينا')), isTrue);
      expect(filter.shows(DateTime(2026, 10, 31, 8), ('a-1', 'لينا')), isFalse);
      expect(filter.shows(DateTime(2025, 11, 9, 8), ('a-1', 'لينا')), isFalse);
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

    test('lists each month once, newest first, and each person once', () {
      expect(
        HistoryFilter.monthsOf(<DateTime>[
          morning,
          DateTime(2026, 11, 10, 9),
          DateTime(2026, 10, 2, 20),
          DateTime(2026, 11, 9, 20),
        ]),
        <DateTime>[DateTime(2026, 11), DateTime(2026, 10)],
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

    test('drops a month or a person the records no longer have', () {
      final HistoryFilter filter = HistoryFilter(
        month: DateTime(2026, 10),
        person: 'a-9',
      );

      expect(
        filter.within(
          <DateTime>[DateTime(2026, 11)],
          <String, String>{'a-1': 'لينا'},
        ),
        HistoryFilter.all,
      );
      expect(
        filter.within(
          <DateTime>[DateTime(2026, 10)],
          <String, String>{'a-9': 'سارة'},
        ),
        filter,
      );
    });
  });
}
