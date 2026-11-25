import 'package:app/features/appointments/domain/entities/appointment_days.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime sun = DateTime(2026, 11, 22);
  final DateTime mon = DateTime(2026, 11, 23);
  final DateTime wed = DateTime(2026, 11, 25);

  group('the main day', () {
    test('changing it leaves the added days', () {
      expect(withMainDay(<DateTime>[sun, mon], wed), <DateTime>[wed, mon]);
    });

    test('a day already added is not kept twice', () {
      expect(withMainDay(<DateTime>[sun, mon], mon), <DateTime>[mon]);
    });

    test('the first day is the main one', () {
      expect(withMainDay(<DateTime>[], sun), <DateTime>[sun]);
    });
  });

  group('«إضافة يوم»', () {
    test('adds after the main day, oldest first', () {
      expect(withAddedDay(<DateTime>[wed, mon], sun), <DateTime>[
        wed,
        sun,
        mon,
      ]);
    });

    test('a day already there changes nothing', () {
      final List<DateTime> days = <DateTime>[sun, mon];
      expect(withAddedDay(days, mon), same(days));
      expect(withAddedDay(days, sun), same(days));
    });

    test('opens on the day after the latest', () {
      expect(dayAfterLast(<DateTime>[wed, sun]), DateTime(2026, 11, 26));
      expect(dayAfterLast(<DateTime>[]), isNull);
    });
  });
}
