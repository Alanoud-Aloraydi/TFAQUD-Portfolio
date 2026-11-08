import 'package:app/core/l10n/arabic_counts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('morning is from Fajr until Asr', () {
    DateTime at(int hour, int minute) => DateTime(2026, 11, 9, hour, minute);
    const String fajr = '04:52';
    const String asr = '15:02';

    expect(isMorning(at(4, 51), fajr: fajr, asr: asr), isFalse);
    expect(isMorning(at(4, 52), fajr: fajr, asr: asr), isTrue);
    expect(isMorning(at(12, 30), fajr: fajr, asr: asr), isTrue);
    expect(isMorning(at(15, 1), fajr: fajr, asr: asr), isTrue);
    expect(isMorning(at(15, 2), fajr: fajr, asr: asr), isFalse);
    // After midnight is still the evening until Fajr.
    expect(isMorning(at(0, 30), fajr: fajr, asr: asr), isFalse);
    // Before the prayer times are loaded: about Riyadh's.
    expect(isMorning(at(10, 0)), isTrue);
    expect(isMorning(at(20, 0)), isFalse);
  });
}
