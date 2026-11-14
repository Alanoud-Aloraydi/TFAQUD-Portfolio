import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/home/data/models/home_model.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  group('ArabicCounts', () {
    test('Arabic counts take the form Arabic uses for each number', () {
      final Map<int, String> forms = <int, String>{
        0: 'zero',
        1: 'one',
        2: 'two',
        3: 'few',
        10: 'few',
        11: 'many',
        90: 'many',
        99: 'many',
        100: 'other',
        101: 'other',
        102: 'other',
        103: 'few',
        111: 'many',
      };
      forms.forEach((int count, String form) {
        expect(arabicPluralForm(count), form, reason: '$count');
      });
    });

    test('morning is from Fajr until Dhuhr', () {
      DateTime at(int hour, int minute) => DateTime(2026, 11, 9, hour, minute);
      const String fajr = '04:52';
      const String dhuhr = '11:48';

      expect(isMorning(at(4, 51), fajr: fajr, dhuhr: dhuhr), isFalse);
      expect(isMorning(at(4, 52), fajr: fajr, dhuhr: dhuhr), isTrue);
      expect(isMorning(at(11, 47), fajr: fajr, dhuhr: dhuhr), isTrue);
      // From Dhuhr on it is «مساء الخير», all afternoon.
      expect(isMorning(at(11, 48), fajr: fajr, dhuhr: dhuhr), isFalse);
      expect(isMorning(at(15, 30), fajr: fajr, dhuhr: dhuhr), isFalse);
      // After midnight is still the evening until Fajr.
      expect(isMorning(at(0, 30), fajr: fajr, dhuhr: dhuhr), isFalse);
      // Before the prayer times are loaded: the fallback times.
      expect(isMorning(at(10, 0)), isTrue);
      expect(isMorning(at(13, 0)), isFalse);
      expect(isMorning(at(20, 0)), isFalse);
    });
  });

  group('ClockText', () {
    setUpAll(initTestLocalization);

    testWidgets('one 12-hour text for "HH:mm" and for a picked time', (
      tester,
    ) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final String am = 'common.am'.tr();
      final String pm = 'common.pm'.tr();
      expect(clockText('00:05'), '12:05 $am');
      expect(clockText('09:30'), '9:30 $am');
      expect(clockText('12:00'), '12:00 $pm');
      expect(clockText('16:30'), '4:30 $pm');
      expect(
        timeOfDayText(const TimeOfDay(hour: 16, minute: 5)),
        clockText('16:05'),
      );
      expect(
        timeOfDayText(const TimeOfDay(hour: 0, minute: 0)),
        clockText('00:00'),
      );
    });
  });

  group('CareVoice', () {
    tearDown(CareVoice.clear);

    test('a caregiver reads the patient\'s name, the patient reads «أنت»', () {
      CareVoice.update(<String, String?>{
        'mine': null,
        'mahmoud': 'محمود',
        'blank': '  ',
      });

      expect(CareVoice.patientOf('mine'), isNull);
      expect(CareVoice.patientOf('mahmoud'), 'محمود');
      expect(CareVoice.patientOf('blank'), isNull);
      expect(CareVoice.patientOf('unknown'), isNull);
      expect(CareVoice.patientOf(null), isNull);

      CareVoice.clear();
      expect(CareVoice.patientOf('mahmoud'), isNull);
    });

    test('home tells who is the patient of each circle', () {
      final home = HomeModel.fromJson(<String, dynamic>{
        'account': <String, dynamic>{
          'id': 'yasser',
          'display_name': 'ياسر',
          'profile_complete': true,
          'avatar_code': null,
        },
        'care_circles': <dynamic>[
          <String, dynamic>{
            'id': 'c-1',
            'name': 'دائرة محمود',
            'can_manage_medications': true,
            'is_patient': false,
            'patient_name': 'محمود',
            'patient_avatar_code': null,
          },
          // An older server: the viewer is taken as the patient, as before.
          <String, dynamic>{'id': 'c-2', 'name': 'صحتي'},
        ],
      }).toEntity();

      expect(home.circles[0].isPatient, isFalse);
      expect(home.circles[0].patientName, 'محمود');
      expect(home.circles[1].isPatient, isTrue);
      expect(home.circles[1].patientName, isNull);
    });
  });

  group('MedicationFormat', () {
    setUpAll(initTestLocalization);

    testWidgets('a dose and a period read the same wherever they show', (
      tester,
    ) async {
      late BuildContext captured;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: Builder(
                builder: (inner) {
                  captured = inner;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        formatMedicationDose(captured, 1, DoseUnit.tablet),
        '1 ${'medications.unit.tablet'.tr()}',
      );
      expect(
        formatMedicationDose(captured, 0.5, DoseUnit.milliliter),
        '0.5 ${'medications.unit.milliliter'.tr()}',
      );
      final DateTime start = DateTime(2026, 3, 3);
      expect(
        formatMedicationPeriod(captured, start, null),
        'medications.starts_on'.tr(
          args: [formatMedicationDate(captured, start)],
        ),
      );
      expect(
        formatMedicationPeriod(captured, start, DateTime(2026, 4, 3)),
        'medications.period'.tr(
          args: [
            formatMedicationDate(captured, start),
            formatMedicationDate(captured, DateTime(2026, 4, 3)),
          ],
        ),
      );
    });
  });
}
