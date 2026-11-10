import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatientClock', () {
    group('PatientClock', () {
      test("the wall time and the day are the patient's, not the phone's", () {
        // 22:30 UTC on 15 October 2026.
        final DateTime instant = DateTime.utc(2026, 10, 15, 22, 30);
        final PatientClock riyadh = PatientClock('Asia/Riyadh');
        final PatientClock toronto = PatientClock('America/Toronto');

        expect(riyadh.wallTime(instant), DateTime.utc(2026, 10, 16, 1, 30));
        expect(riyadh.today(instant), DateTime(2026, 10, 16));
        expect(toronto.wallTime(instant), DateTime.utc(2026, 10, 15, 18, 30));
        expect(toronto.today(instant), DateTime(2026, 10, 15));
      });

      test('now reads the injected clock', () {
        final PatientClock clock = PatientClock(
          'Asia/Riyadh',
          clock: () => DateTime.utc(2026, 11, 10, 9),
        );
        expect(clock.now(), DateTime.utc(2026, 11, 10, 12));
      });

      test('08:00 in London keeps its wall time across DST', () {
        final PatientClock london = PatientClock('Europe/London');

        // Summer time (UTC+1) until 25 October 2026, then UTC.
        expect(
          london.momentOf(DateTime(2026, 10, 24), '08:00'),
          DateTime.utc(2026, 10, 24, 7),
        );
        expect(
          london.momentOf(DateTime(2026, 10, 26), '08:00'),
          DateTime.utc(2026, 10, 26, 8),
        );
        // A real day across the change is 25 hours.
        expect(
          london
              .momentOf(DateTime(2026, 10, 26), '00:00')
              .difference(london.momentOf(DateTime(2026, 10, 25), '00:00')),
          const Duration(hours: 25),
        );
      });

      test('a time skipped by the spring jump lands after it', () {
        // 01:30 does not exist in London on 29 March 2026.
        final DateTime moment = PatientClock('Europe/London')
            .momentOf(DateTime(2026, 3, 29), '01:30');
        expect(moment.isAfter(DateTime.utc(2026, 3, 29, 0, 59)), isTrue);
        expect(moment.isBefore(DateTime.utc(2026, 3, 29, 2)), isTrue);
      });

      test('an unknown zone falls back to the default one', () {
        expect(PatientClock('Mars/Olympus').zone, defaultPatientZone);
      });

      test('two clocks of one zone are equal', () {
        expect(PatientClock('Europe/London'), PatientClock('Europe/London'));
      });
    });

    test('latestToday is the day at UTC+14', () {
      expect(
        latestToday(DateTime.utc(2026, 10, 15, 9, 59)),
        DateTime(2026, 10, 15),
      );
      expect(
        latestToday(DateTime.utc(2026, 10, 15, 10)),
        DateTime(2026, 10, 16),
      );
    });

    test('wallClockAt needs no zone', () {
      expect(
        wallClockAt(DateTime(2026, 11, 9), '07:05'),
        DateTime.utc(2026, 11, 9, 7, 5),
      );
    });

    test('a listed Saudi city has a zone; a typed one has none', () {
      expect(SaudiCities.zoneOf('جدة'), defaultPatientZone);
      expect(SaudiCities.zoneOf('لندن'), isNull);
      expect(SaudiCities.zoneOf(null), isNull);
    });

    test('ShownCircleClock follows the circle shown', () {
      final ShownCircleClock shown = ShownCircleClock();
      addTearDown(shown.dispose);
      int changes = 0;
      shown.addListener(() => changes++);

      expect(shown.value.zone, defaultPatientZone);
      shown.show('Europe/London');
      shown.show('Europe/London');

      expect(shown.value.zone, 'Europe/London');
      expect(changes, 1);
    });

    testWidgets('PatientClockScope gives its clock, the default without one', (
      WidgetTester tester,
    ) async {
      PatientClock? read;
      Widget reader() => Builder(
        builder: (BuildContext context) {
          read = PatientClockScope.of(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(reader());
      expect(read!.zone, defaultPatientZone);

      await tester.pumpWidget(
        PatientClockScope(
          clock: PatientClock('Europe/London'),
          child: reader(),
        ),
      );
      expect(read!.zone, 'Europe/London');
    });
  });
}
