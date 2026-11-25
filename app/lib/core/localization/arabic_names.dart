import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/widgets.dart';

/// [name] with «ال» before it, as Arabic says a known thing: «الأنسولين».
/// A name that has it already («البنادول»), or that is not written in
/// Arabic («Panadol»), stays as it is.
String withArticle(String name) {
  final String value = name.trim();
  if (value.isEmpty || value.startsWith('ال')) return value;
  final int first = value.codeUnitAt(0);
  // The Arabic letters, hamza to yeh.
  final bool arabic = first >= 0x0621 && first <= 0x064A;
  return arabic ? 'ال$value' : value;
}

/// «مراجعة، عيادة السكري»: the visit's kind, then the clinic or doctor
/// when one was typed. For notifications and the calendar, with no context.
String visitName(CareAppointment visit) {
  final String kind = visit.kind == AppointmentKind.other
      ? visit.otherKind ?? 'appointments.kinds.other'.tr()
      : 'appointments.kinds.${visit.kind.name}'.tr();
  final String? clinic = appointmentClinic(visit);
  return clinic == null ? kind : '$kind، $clinic';
}

/// «4:30 م» for "16:30", the same as the app's pages show a time.
String clockText(String time) {
  final List<String> parts = time.split(':');
  return _twelveHour(int.parse(parts[0]), int.parse(parts[1]));
}

/// «4:30 م» for [time] picked on a wheel; the same text as [clockText].
String timeOfDayText(TimeOfDay time) => _twelveHour(time.hour, time.minute);

/// «4:30 م» for the wall time [at] (`PatientClock.wallTime`); the same text
/// as [clockText].
String wallTimeText(DateTime at) => _twelveHour(at.hour, at.minute);

String _twelveHour(int hour, int minute) =>
    '${hour % 12 == 0 ? 12 : hour % 12}:'
    '${minute.toString().padLeft(2, '0')} '
    '${(hour < 12 ? 'common.am' : 'common.pm').tr()}';

/// Arabic counted words, the way they are said: «دقيقة» (1), «دقيقتين» (2),
/// «3 دقائق» to «10 دقائق», then «11 دقيقة» and on. The forms are the
/// `counts.*` keys (zero, one, two, few, many, other), chosen by Arabic's
/// plural rules in [arabicPluralForm].
enum ArabicCount { minutes, hours, days }

/// Which plural form Arabic uses for [count] (the CLDR rules): 0 zero, 1 one,
/// 2 two, 3 to 10 few, 11 to 99 many, and 100, 101, 102 other; past 100
/// the last two digits decide, so 103 is few.
///
/// The app chooses it here rather than with `context.plural`: by default
/// easy_localization ignores a language's own rules and says «other» for
/// every number past 2, which would be «3 يوم».
String arabicPluralForm(int count) {
  if (count == 0) return 'zero';
  if (count == 1) return 'one';
  if (count == 2) return 'two';
  final int lastTwo = count % 100;
  if (lastTwo >= 3 && lastTwo <= 10) return 'few';
  if (lastTwo >= 11) return 'many';
  return 'other';
}

/// [count] of [unit], «3 دقائق».
String arabicCount(BuildContext context, ArabicCount unit, int count) =>
    context.tr(
      'counts.${unit.name}.${arabicPluralForm(count)}',
      args: <String>['$count'],
    );
