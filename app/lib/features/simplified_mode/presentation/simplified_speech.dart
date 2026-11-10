import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The words the simplified mode says in place of what it writes for the
/// eye: a clock time, a unit, a mark. All of them come from the
/// translations, so [toSpeech] itself is plain text work.
class SpeechWords {
  const SpeechWords({
    required this.clock,
    required this.hours,
    required this.quarter,
    required this.third,
    required this.half,
    required this.toThird,
    required this.toQuarter,
    required this.minutes,
    required this.minutesFew,
    required this.morning,
    required this.evening,
    required this.morningMarks,
    required this.afternoonMarks,
    required this.over,
    required this.units,
    required this.say,
  });

  /// Read from the translations of [context].
  factory SpeechWords.of(BuildContext context) {
    String word(String key) => context.tr('simplified_mode.speech.$key');
    final Map<String, String> units = <String, String>{
      context.tr('measurements.glucose_unit'): word('unit.glucose'),
      context.tr('measurements.bp_unit'): word('unit.bp'),
      for (final String name in const <String>[
        'milligram',
        'microgram',
        'milligramPerMilliliter',
        'milligramPerFiveMilliliters',
        'microgramPerDose',
        'unitPerMilliliter',
        'percent',
      ])
        context.tr('medications.strength_display.$name'): word('unit.$name'),
      context.tr('medications.unit.milliliter'): word('unit.milliliter'),
    };
    return SpeechWords(
      clock: word('clock'),
      hours: <String>[
        for (int hour = 1; hour <= 12; hour++) word('hour.$hour'),
      ],
      quarter: word('quarter'),
      third: word('third'),
      half: word('half'),
      toThird: word('to_third'),
      toQuarter: word('to_quarter'),
      minutes: word('minutes'),
      minutesFew: word('minutes_few'),
      morning: word('morning'),
      evening: word('evening'),
      morningMarks: <String>{
        context.tr('simplified_mode.am'),
        context.tr('common.am'),
      },
      afternoonMarks: <String>{
        context.tr('simplified_mode.pm'),
        context.tr('common.pm'),
      },
      over: word('over'),
      units: units,
      say: <String, String>{
        for (final String pair in word('say').split('|'))
          if (pair.split('=') case [final String shown, final String spoken])
            shown: spoken,
      },
    );
  }

  /// «الساعة {}».
  final String clock;

  /// The hours one to twelve as said on a clock: «التاسعة».
  final List<String> hours;

  /// «{} والربع», «{} والثلث», «{} والنصف»: the hour, then the minutes.
  final String quarter;
  final String third;
  final String half;

  /// «{} إلا ثلثًا», «{} إلا ربعًا»: the next hour, then the minutes.
  final String toThird;
  final String toQuarter;

  /// «{} و{} دقيقة» and, for three to ten minutes, «{} و{} دقائق».
  final String minutes;
  final String minutesFew;

  /// «صباحًا» and «مساءً».
  final String morning;
  final String evening;

  /// The marks after a written time that mean before noon («صباحًا», «ص»)
  /// and after it («مساءً», «م»).
  final Set<String> morningMarks;
  final Set<String> afternoonMarks;

  /// «على», between the two numbers of a blood pressure.
  final String over;

  /// Each written unit («ملغ/دل») and how it is said.
  final Map<String, String> units;

  /// Words the phone's voice says wrongly, with the marks that make it say
  /// them right: «تفقد» as «تَفَقُّد».
  final Map<String, String> say;
}

/// [lines], the texts of one part of a screen, as one spoken part: each a
/// sentence, so the voice pauses between them. Empty lines are left out.
String sentences(Iterable<String> lines) => lines
    .map((String line) => line.trim())
    .where((String line) => line.isNotEmpty)
    .join('. ');

/// Arabic and Persian digits, as the app may write them, to 0-9.
final RegExp _easternDigit = RegExp('[٠-٩۰-۹]');

/// A written clock time with its mark, and «الساعة» before it if written:
/// «الساعة 9:30 م», «6:00 مساءً».
final RegExp _time = RegExp(
  r'(الساعة\s*)?\b(\d{1,2}):(\d{2})\s*([^\s\d.,،]+)?',
);

/// Two numbers with a slash: a blood pressure, «120/80».
final RegExp _pressure = RegExp(r'(\d+)\s*/\s*(\d+)');

/// Quotation marks, which are only for the eye.
final RegExp _quotes = RegExp('[«»"“”]');

/// Marks that part a line for the eye and a pause for the ear.
final RegExp _breaks = RegExp(r'\s*[·•←→—–|()]\s*|\s*:\s+');

final RegExp _repeatedPauses = RegExp(r'(\s*،\s*)+');
final RegExp _spaces = RegExp(r'\s+');

/// A pause left at either end, as after «(الكبير)».
final RegExp _edgePauses = RegExp(r'^[\s،]+|[\s،]+$');

/// [shown], the text a screen writes, as it should be said: times as a
/// clock is read («الساعة التاسعة والنصف مساءً»), units in full, a blood
/// pressure as «120 على 80», marks dropped or turned into pauses, and the
/// words in [SpeechWords.say] with their vowel marks.
String toSpeech(String shown, SpeechWords words) {
  String text = shown.replaceAllMapped(
    _easternDigit,
    (Match digit) => '${_easternValue(digit[0]!)}',
  );
  text = text.replaceAllMapped(_time, (Match match) {
    final String clock = words.clock.replaceFirst(
      '{}',
      _clockWords(int.parse(match[2]!), int.parse(match[3]!), words),
    );
    // The word after the time: its morning or evening mark, or the next
    // word of the sentence, which stays.
    final String? next = match[4];
    if (next == null) return clock;
    if (words.afternoonMarks.contains(next)) return '$clock ${words.evening}';
    if (words.morningMarks.contains(next)) return '$clock ${words.morning}';
    return '$clock $next';
  });
  for (final MapEntry<String, String> unit in _longestFirst(words.units)) {
    text = _replaceWord(text, unit.key, unit.value);
  }
  text = text.replaceAllMapped(
    _pressure,
    (Match match) => '${match[1]} ${words.over} ${match[2]}',
  );
  for (final MapEntry<String, String> word in _longestFirst(words.say)) {
    text = _replaceWord(text, word.key, word.value);
  }
  return text
      .replaceAll(_quotes, '')
      .replaceAll(_breaks, '، ')
      .replaceAll(_repeatedPauses, '، ')
      .replaceAll(_spaces, ' ')
      .replaceAll(_edgePauses, '');
}

int _easternValue(String digit) {
  final int code = digit.codeUnitAt(0);
  return code >= 0x06F0 ? code - 0x06F0 : code - 0x0660;
}

/// The hour and minutes as a clock is read: «التاسعة والنصف».
String _clockWords(int hour24, int minute, SpeechWords words) {
  String hour(int value) => words.hours[(value + 11) % 12];
  final int twelve = hour24 % 12 == 0 ? 12 : hour24 % 12;
  String fill(String pattern, String first, [String? second]) {
    final String once = pattern.replaceFirst('{}', first);
    return second == null ? once : once.replaceFirst('{}', second);
  }

  return switch (minute) {
    0 => hour(twelve),
    15 => fill(words.quarter, hour(twelve)),
    20 => fill(words.third, hour(twelve)),
    30 => fill(words.half, hour(twelve)),
    40 => fill(words.toThird, hour(twelve + 1)),
    45 => fill(words.toQuarter, hour(twelve + 1)),
    >= 3 && <= 10 => fill(words.minutesFew, hour(twelve), '$minute'),
    _ => fill(words.minutes, hour(twelve), '$minute'),
  };
}

Iterable<MapEntry<String, String>> _longestFirst(Map<String, String> map) =>
    map.entries.toList()..sort((a, b) => b.key.length.compareTo(a.key.length));

/// [text] with [shown] replaced by [spoken] where it stands as a word of its
/// own (or right after a number, as in «500ملغ»), never inside another word.
String _replaceWord(String text, String shown, String spoken) {
  if (shown.isEmpty) return text;
  final RegExp word = RegExp(
    '(?<![\\u0600-\\u06FF])${RegExp.escape(shown)}(?![\\u0600-\\u06FF])',
  );
  // Spaced, so a unit written against its number is said apart from it;
  // [toSpeech] folds the extra spaces.
  return text.replaceAll(word, ' $spoken ');
}
