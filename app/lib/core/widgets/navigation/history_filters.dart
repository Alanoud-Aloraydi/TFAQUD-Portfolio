import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The two filters of a history side by side: the month, among [months]
/// that have records, and who recorded, among [people] (key to name). «كل
/// الشهور» and «كل الأشخاص» show everything.
class HistoryFilters extends StatelessWidget {
  const HistoryFilters({
    super.key,
    required this.months,
    required this.people,
    required this.filter,
    required this.onChanged,
  });

  final List<DateTime> months;
  final Map<String, String> people;
  final HistoryFilter filter;
  final ValueChanged<HistoryFilter> onChanged;

  static String _key(DateTime month) => month.toIso8601String();

  @override
  Widget build(BuildContext context) {
    final Map<String, String> monthOptions = <String, String>{
      '': context.tr('history.all_months'),
      for (final DateTime month in months)
        _key(month): formatMonth(context, month),
    };
    final Map<String, String> personOptions = <String, String>{
      '': context.tr('history.all_people'),
      ...people,
    };
    final String month = filter.month == null ? '' : _key(filter.month!);
    final String person = filter.person ?? '';
    return Row(
      children: <Widget>[
        Flexible(
          child: WhiteFilterMenu<String>(
            options: monthOptions,
            selected: monthOptions.containsKey(month) ? month : '',
            onChanged: (String value) => onChanged(
              filter.withMonth(value.isEmpty ? null : DateTime.parse(value)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: WhiteFilterMenu<String>(
            options: personOptions,
            selected: personOptions.containsKey(person) ? person : '',
            onChanged: (String value) =>
                onChanged(filter.withPerson(value.isEmpty ? null : value)),
          ),
        ),
      ],
    );
  }
}
