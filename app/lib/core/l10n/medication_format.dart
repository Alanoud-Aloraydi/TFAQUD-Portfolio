import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A strength or dose number as the API and the forms write it: «500» for
/// 500.0, «0.5» for 0.5 (no trailing «.0»). Shared by the medication
/// screens of both modes, the emergency card and the record export.
String formatMedicationNumber(double value) =>
    value.toString().replaceFirst(RegExp(r'\.0$'), '');

/// «3 مارس 2026»: a treatment or schedule day with the Arabic month name.
String formatMedicationDate(BuildContext context, DateTime date) =>
    '${date.day} ${context.tr('circles.months.${date.month}')} ${date.year}';

/// «يبدأ في 3 مارس 2026» for a plan without an end, «من 3 مارس 2026 إلى
/// 3 أبريل 2026» for one with it.
String formatMedicationPeriod(
  BuildContext context,
  DateTime start,
  DateTime? end,
) => end == null
    ? context.tr(
        'medications.starts_on',
        args: [formatMedicationDate(context, start)],
      )
    : context.tr(
        'medications.period',
        args: [
          formatMedicationDate(context, start),
          formatMedicationDate(context, end),
        ],
      );

/// One dose of a schedule or an occurrence, «1 قرص».
String formatMedicationDose(
  BuildContext context,
  double value,
  DoseUnit unit,
) => context.tr(
  'medications.dose',
  args: [
    formatMedicationNumber(value),
    context.tr('medications.unit.${unit.name}'),
  ],
);

/// A monthly schedule's days, «شهريًا: يوم 1، 15».
String formatMonthDays(BuildContext context, List<int> days) => context.tr(
  'medications.monthly_days',
  args: <String>[
    (days.toList()..sort()).join(context.tr('medications.list_separator')),
  ],
);

/// An interval schedule's days, «كل يوم», «كل يومين», «كل 3 أيام».
String formatInterval(BuildContext context, int days) => context.tr(
  'medications.every',
  args: <String>[arabicCount(context, ArabicCount.days, days)],
);
