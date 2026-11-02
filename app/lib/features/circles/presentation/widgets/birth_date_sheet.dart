import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/circles/domain/birth_date_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Opens the birth date sheet. Returns the confirmed date, or null when the
/// sheet is closed without confirming. [today] is only for tests.
///
/// It is the app's one date picker (the iOS wheel of [DateWheelSheet]),
/// limited to what [BirthDateRules] allows: from 1900 up to today.
Future<DateTime?> showBirthDateSheet(
  BuildContext context, {
  DateTime? selected,
  DateTime? today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        BirthDateSheet(selected: selected, today: today ?? DateTime.now()),
  );
}

/// The date as a field shows it, "12 مارس 1964": the day and the year are
/// written with the digits 0 to 9, like every number of the app.
String formatBirthDate(BuildContext context, DateTime date) {
  final String month = context.tr('circles.months.${date.month}');
  return '${date.day} $month ${date.year}';
}

/// The birth date wheel. With no date chosen yet it opens about 40 years
/// back, on the first of January.
class BirthDateSheet extends StatelessWidget {
  const BirthDateSheet({super.key, this.selected, required this.today});

  final DateTime? selected;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final DateTime last = DateUtils.dateOnly(today);
    return DateWheelSheet(
      title: context.tr('circles.birth_date'),
      confirmLabel: context.tr('circles.date_confirm'),
      initialDate: BirthDateRules.clamp(
        selected?.year ?? today.year - 40,
        selected?.month ?? 1,
        selected?.day ?? 1,
        today,
      ),
      firstDate: DateTime(BirthDateRules.firstYear),
      lastDate: last,
    );
  }
}
