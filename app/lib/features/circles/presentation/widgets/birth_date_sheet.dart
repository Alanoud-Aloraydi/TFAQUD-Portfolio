import 'dart:math' as math;

import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/circles/domain/birth_date_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Opens the birth date sheet. Returns the confirmed date, or null when the
/// sheet is closed without confirming. [today] is only for tests.
///
/// The app writes every number with the digits 0 to 9. The date picker of
/// Flutter writes the digits of the language (٠ to ٩), so the app has its own
/// sheet: a list of days, a list of months and a list of years.
Future<DateTime?> showBirthDateSheet(
  BuildContext context, {
  DateTime? selected,
  DateTime? today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
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

/// Three lists (day, month, year) and the confirm button. A tap on a value only
/// marks it; the confirm button returns the date.
class BirthDateSheet extends StatefulWidget {
  const BirthDateSheet({super.key, this.selected, required this.today});

  final DateTime? selected;
  final DateTime today;

  @override
  State<BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<BirthDateSheet> {
  late DateTime _date = BirthDateRules.clamp(
    // A birth year is far back: the lists start around 40 years ago.
    widget.selected?.year ?? widget.today.year - 40,
    widget.selected?.month ?? 1,
    widget.selected?.day ?? 1,
    widget.today,
  );

  void _choose({int? year, int? month, int? day}) {
    setState(() {
      _date = BirthDateRules.clamp(
        year ?? _date.year,
        month ?? _date.month,
        day ?? _date.day,
        widget.today,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                context.tr('circles.birth_date'),
                style: text.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            // In a right-to-left language the first column is on the right:
            // day, month, year, as an Arabic date is read.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _ValueColumn(
                    label: context.tr('circles.day_label'),
                    values: BirthDateRules.days(
                      _date.year,
                      _date.month,
                      widget.today,
                    ),
                    selected: _date.day,
                    format: (int day) => day.toString(),
                    onSelected: (int day) => _choose(day: day),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _ValueColumn(
                    label: context.tr('circles.month_label'),
                    values: BirthDateRules.months(_date.year, widget.today),
                    selected: _date.month,
                    format: (int month) => context.tr('circles.months.$month'),
                    onSelected: (int month) => _choose(month: month),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ValueColumn(
                    label: context.tr('circles.year_label'),
                    values: BirthDateRules.years(widget.today),
                    selected: _date.year,
                    format: (int year) => year.toString(),
                    onSelected: (int year) => _choose(year: year),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PillButton(
              label: context.tr('circles.date_confirm'),
              onPressed: () => Navigator.of(context).pop(_date),
            ),
          ],
        ),
      ),
    );
  }
}

/// One scrolling list of numbers with a label above it. It opens with the
/// chosen value in view.
class _ValueColumn extends StatefulWidget {
  const _ValueColumn({
    required this.label,
    required this.values,
    required this.selected,
    required this.format,
    required this.onSelected,
  });

  final String label;
  final List<int> values;
  final int selected;
  final String Function(int value) format;
  final ValueChanged<int> onSelected;

  @override
  State<_ValueColumn> createState() => _ValueColumnState();
}

class _ValueColumnState extends State<_ValueColumn> {
  static const double _itemExtent = 48;
  static const double _height = 240;

  late final ScrollController _controller = ScrollController(
    initialScrollOffset: _offsetOf(widget.selected),
  );

  /// Puts [value] in the middle of the list, as far as the list allows.
  double _offsetOf(int value) {
    final int index = widget.values.indexOf(value);
    if (index < 0) return 0;
    final double middle = index * _itemExtent - (_height - _itemExtent) / 2;
    final double last = widget.values.length * _itemExtent - _height;
    return math.min(math.max(middle, 0), math.max(last, 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: text.titleSmall?.copyWith(color: AppColors.ink2),
        ),
        const SizedBox(height: 8),
        Container(
          height: _height,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            controller: _controller,
            itemExtent: _itemExtent,
            itemCount: widget.values.length,
            itemBuilder: (BuildContext context, int index) {
              final int value = widget.values[index];
              final bool chosen = value == widget.selected;
              return Semantics(
                button: true,
                selected: chosen,
                child: InkWell(
                  onTap: () => widget.onSelected(value),
                  child: Container(
                    alignment: Alignment.center,
                    color: chosen ? AppColors.brandTint : null,
                    child: Text(
                      widget.format(value),
                      style: text.bodyLarge?.copyWith(
                        color: chosen ? AppColors.brand : AppColors.ink,
                        fontWeight: chosen ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
