import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The simplified mode's way of writing a time: «6:00 مساءً».
String simplifiedTime(BuildContext context, String time) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final String minute = parts[1].padLeft(2, '0');
  final String period = context.tr(
    hour < 12 ? 'simplified_mode.am' : 'simplified_mode.pm',
  );
  return '${hour % 12 == 0 ? 12 : hour % 12}:$minute $period';
}

/// The app's one greeting, the detailed mode's too: «صباح الخير، مريم»
/// from Fajr until Asr, «مساء الخير، مريم» after ([prayers] is today's;
/// without it, about where those prayers fall in Riyadh).
String simplifiedGreeting(
  BuildContext context,
  String? name,
  DateTime now,
  PrayerDay? prayers,
) => greeting(
  context,
  riyadhNow(now),
  name,
  fajr: prayers?.times[Prayer.fajr],
  asr: prayers?.times[Prayer.asr],
);

/// «اليوم · الجمعة 6 نوفمبر».
String simplifiedToday(BuildContext context, DateTime now) {
  final DateTime day = riyadhToday(now);
  return context.tr(
    'simplified_mode.today_date',
    args: <String>[
      context.tr('common.weekdays.${day.weekday}'),
      '${day.day}',
      context.tr('circles.months.${day.month}'),
    ],
  );
}

/// How long until [at] (Riyadh wall time) from [now], in the detailed
/// mode's words: «بعد ساعتين», «بعد 3 دقائق», or «الآن» once it came.
String simplifiedUntil(BuildContext context, DateTime at, DateTime now) {
  final int minutes = at.difference(riyadhNow(now)).inMinutes;
  if (minutes <= 0) return context.tr('simplified_mode.now');
  return afterDuration(context, minutes);
}

/// What to take: «حبة واحدة», or «2 حبة».
String simplifiedDoseAmount(BuildContext context, DoseOccurrence dose) {
  if (dose.doseValue == 1) {
    return context.tr('simplified_mode.dose_one.${dose.doseUnit.name}');
  }
  return context.tr(
    'medications.dose',
    args: <String>[
      formatMedicationNumber(dose.doseValue),
      context.tr('medications.unit.${dose.doseUnit.name}'),
    ],
  );
}

/// The medicine's strength: «500 ملغ».
String simplifiedStrength(BuildContext context, DoseOccurrence dose) =>
    '${formatMedicationNumber(dose.strengthValue)} '
    '${context.tr('medications.strength_display.${dose.strengthUnit.name}')}';

/// «قياس الضغط» or «قياس السكر».
String simplifiedMeasurementTitle(BuildContext context, MeasurementKind kind) =>
    context.tr('simplified_mode.measure_${kind.name}');

/// A task's name on a row or a card.
String simplifiedTaskTitle(BuildContext context, TodayTask task) =>
    switch (task.kind) {
      TodayTaskKind.medication => task.dose!.name,
      TodayTaskKind.measurement => simplifiedMeasurementTitle(
        context,
        task.measurement!.kind,
      ),
      TodayTaskKind.appointment => appointmentTitle(context, task.appointment!),
    };

/// «بعد المغرب».
String simplifiedPeriod(BuildContext context, PrayerPeriod period) =>
    context.tr('simplified_mode.period.${period.name}');

/// The plain part of the day beside a period: «المساء».
String simplifiedPeriodHint(BuildContext context, PrayerPeriod period) =>
    context.tr('simplified_mode.period_hint.${period.name}');
