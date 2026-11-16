import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/widgets/layout/collapsible_group.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/navigation/history_filters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A history gathered in a [CollapsibleGroup] titled [title], the way
/// «يحتاج انتباهك» gathers its cards, with [HistoryFilters] at its top:
/// [items] narrowed to one day ([dayOf]) and to who recorded ([byOf]: their
/// account and name), then drawn by [builder]. [empty] stands in when
/// there are no items at all; [footer] stays last («أقدم»).
class FilteredHistory<T> extends StatefulWidget {
  const FilteredHistory({
    super.key,
    required this.title,
    required this.items,
    required this.dayOf,
    required this.byOf,
    required this.builder,
    required this.empty,
    this.footer,
  });

  final String title;
  final List<T> items;
  final DateTime Function(T item) dayOf;
  final (String?, String?) Function(T item) byOf;
  final Widget Function(List<T> shown) builder;
  final Widget empty;
  final Widget? footer;

  @override
  State<FilteredHistory<T>> createState() => _FilteredHistoryState<T>();
}

class _FilteredHistoryState<T> extends State<FilteredHistory<T>> {
  bool _expanded = true;
  HistoryFilter _filter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final List<DateTime> months = HistoryFilter.monthsOf(
      widget.items.map(widget.dayOf),
    );
    final Map<String, String> people = HistoryFilter.peopleOf(
      widget.items.map(widget.byOf),
    );
    // A month or a person the items no longer have is off.
    final HistoryFilter filter = _filter.within(months, people);
    final List<T> shown = <T>[
      for (final T item in widget.items)
        if (filter.shows(widget.dayOf(item), widget.byOf(item))) item,
    ];
    return CollapsibleGroup(
      title: widget.title,
      count: shown.length,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.items.isEmpty)
            widget.empty
          else ...<Widget>[
            HistoryFilters(
              months: months,
              people: people,
              filter: filter,
              onChanged: (next) => setState(() => _filter = next),
            ),
            const SizedBox(height: AppSpacing.md),
            if (shown.isEmpty)
              InsetText(context.tr('history.none_match'))
            else
              widget.builder(shown),
          ],
          ?widget.footer,
        ],
      ),
    );
  }
}
