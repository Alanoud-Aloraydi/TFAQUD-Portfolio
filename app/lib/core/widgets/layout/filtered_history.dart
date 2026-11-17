import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/utils/history_view.dart';
import 'package:app/core/widgets/layout/collapsible_group.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/navigation/history_filters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A history in a [CollapsibleGroup] titled [title], with [HistoryFilters]
/// at its top: [items] narrowed to a month ([dayOf]), to who recorded
/// ([byOf]) and to one of [kinds] ([kindOf]), drawn by [builder]. [empty]
/// stands for no items at all; [footer] stays last («أقدم»).
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
    this.kinds = const <String, String>{},
    this.kindOf,
  });

  final String title;
  final List<T> items;
  final DateTime Function(T item) dayOf;
  final (String?, String?) Function(T item) byOf;
  final Widget Function(List<T> shown) builder;
  final Widget empty;
  final Widget? footer;
  final Map<String, String> kinds;
  final String Function(T item)? kindOf;

  @override
  State<FilteredHistory<T>> createState() => _FilteredHistoryState<T>();
}

class _FilteredHistoryState<T> extends State<FilteredHistory<T>> {
  bool _expanded = true;
  HistoryFilter _filter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final HistoryView<T> view = HistoryView<T>(
      widget.items,
      _filter,
      dayOf: widget.dayOf,
      byOf: widget.byOf,
      kinds: widget.kinds,
      kindOf: widget.kindOf,
    );
    return CollapsibleGroup(
      title: widget.title,
      count: view.shown.length,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.items.isEmpty)
            widget.empty
          else ...<Widget>[
            HistoryFilters(
              months: view.months,
              people: view.people,
              kinds: view.kinds,
              filter: view.filter,
              onChanged: (next) => setState(() => _filter = next),
            ),
            const SizedBox(height: AppSpacing.md),
            if (view.shown.isEmpty)
              InsetText(context.tr('history.none_match'))
            else
              widget.builder(view.shown),
          ],
          ?widget.footer,
        ],
      ),
    );
  }
}
