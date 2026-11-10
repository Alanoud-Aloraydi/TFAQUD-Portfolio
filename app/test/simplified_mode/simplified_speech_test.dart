import 'package:app/features/simplified_mode/presentation/simplified_speech.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/widget_harness.dart';

/// The app's words, as [SpeechWords.of] reads them from ar.json.
const SpeechWords _words = SpeechWords(
  clock: 'الساعة {}',
  hours: <String>[
    'الواحدة',
    'الثانية',
    'الثالثة',
    'الرابعة',
    'الخامسة',
    'السادسة',
    'السابعة',
    'الثامنة',
    'التاسعة',
    'العاشرة',
    'الحادية عشرة',
    'الثانية عشرة',
  ],
  quarter: '{} والربع',
  third: '{} والثلث',
  half: '{} والنصف',
  toThird: '{} إلا ثلثًا',
  toQuarter: '{} إلا ربعًا',
  minutes: '{} و{} دقيقة',
  minutesFew: '{} و{} دقائق',
  morning: 'صباحًا',
  evening: 'مساءً',
  morningMarks: <String>{'صباحًا', 'ص'},
  afternoonMarks: <String>{'مساءً', 'م'},
  over: 'على',
  units: <String, String>{
    'ملغ/دل': 'مِلِّيغرام لكل دِيسِيلِتر',
    'ملغ': 'مِلِّيغرام',
    'مل': 'مِلِّيلِتر',
    '%': 'بالمئة',
  },
  say: <String, String>{'تفقد': 'تَفَقُّد', 'حبة': 'حَبَّة'},
);

void main() {
  group('SimplifiedSpeech', () {
    group('toSpeech says a clock time as it is read', () {
      test('on the hour, and with a quarter, a third or a half', () {
        expect(toSpeech('9:00', _words), 'الساعة التاسعة');
        expect(toSpeech('12:00 ص', _words), 'الساعة الثانية عشرة صباحًا');
        expect(
          toSpeech('موعده كان 9:30 مساءً', _words),
          'موعده كان الساعة التاسعة والنصف مساءً',
        );
        expect(toSpeech('٩:٢٠ م', _words), 'الساعة التاسعة والثلث مساءً');
      });

      test('before the next hour', () {
        expect(
          toSpeech('11:45 م', _words),
          'الساعة الثانية عشرة إلا ربعًا مساءً',
        );
        expect(
          toSpeech('7:40 صباحًا', _words),
          'الساعة الثامنة إلا ثلثًا صباحًا',
        );
      });

      test('with other minutes, counted in the right plural', () {
        expect(toSpeech('9:05 ص', _words), 'الساعة التاسعة و5 دقائق صباحًا');
        expect(toSpeech('9:12 م', _words), 'الساعة التاسعة و12 دقيقة مساءً');
      });

      test('without saying «الساعة» twice', () {
        expect(
          toSpeech('الساعة 4:30 م · مستشفى الملك فهد', _words),
          'الساعة الرابعة والنصف مساءً، مستشفى الملك فهد',
        );
      });
    });

    test('toSpeech says units in full, also against their number', () {
      expect(toSpeech('120 ملغ/دل', _words), '120 مِلِّيغرام لكل دِيسِيلِتر');
      expect(toSpeech('500ملغ', _words), '500 مِلِّيغرام');
      expect(toSpeech('1 مل', _words), '1 مِلِّيلِتر');
      expect(toSpeech('تركيز 5%', _words), 'تركيز 5 بالمئة');
    });

    test('toSpeech changes no word that only contains a unit', () {
      expect(toSpeech('مستشفى الملك فهد', _words), 'مستشفى الملك فهد');
    });

    test('toSpeech says a blood pressure as «120 على 80»', () {
      expect(
        toSpeech('سجّلنا الضغط: 120/80', _words),
        'سجّلنا الضغط، 120 على 80',
      );
    });

    test('toSpeech drops the marks that are only for the eye', () {
      expect(toSpeech('«تفقد» · تذكير', _words), 'تَفَقُّد، تذكير');
      expect(
        toSpeech('اكتب الرقم الأعلى (الكبير)', _words),
        'اكتب الرقم الأعلى، الكبير',
      );
    });

    test('toSpeech gives the vowel marks of a word the voice says wrongly', () {
      expect(toSpeech('2 حبة', _words), '2 حَبَّة');
    });

    test('sentences makes one spoken part of a card\'s lines', () {
      expect(
        sentences(<String>['قياس السكر', '  ', 'بعد المغرب']),
        'قياس السكر. بعد المغرب',
      );
    });

    testWidgets('every word SpeechWords reads is in the translations', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      late SpeechWords words;
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
                builder: (context) {
                  words = SpeechWords.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A key missing from ar.json comes back as the key itself.
      final List<String> spoken = <String>[
        words.clock,
        ...words.hours,
        words.quarter,
        words.third,
        words.half,
        words.toThird,
        words.toQuarter,
        words.minutes,
        words.minutesFew,
        words.morning,
        words.evening,
        ...words.morningMarks,
        ...words.afternoonMarks,
        words.over,
        ...words.units.keys,
        ...words.units.values,
      ];
      for (final String word in spoken) {
        expect(word, isNot(contains('simplified_mode.')), reason: word);
        expect(word, isNot(contains('medications.')), reason: word);
        expect(word, isNot(contains('measurements.')), reason: word);
      }
      expect(words.hours, hasLength(12));
      expect(words.hours[8], 'التاسعة');
      expect(words.units['ملغ/دل'], 'مِلِّيغرام لكل دِيسِيلِتر');
      expect(words.say['تفقد'], 'تَفَقُّد');
      expect(
        toSpeech('الساعة 9:30 م · 120 ملغ/دل', words),
        'الساعة التاسعة والنصف مساءً، 120 مِلِّيغرام لكل دِيسِيلِتر',
      );
    });
  });
}
