import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/utils/history_view.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/layout/expand_reveal.dart';
import 'package:app/core/widgets/layout/group_header.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/navigation/glass_filter_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A history in a [CollapsibleGroup] titled [title], with [HistoryFilters]
/// at its top: [items] narrowed to a month ([dayOf]) and to who recorded
/// ([byOf]), drawn by [builder]. [empty] stands for no items at all;
/// [footer] stays last («أقدم»).
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
    final HistoryView<T> view = HistoryView<T>(
      widget.items,
      _filter,
      dayOf: widget.dayOf,
      byOf: widget.byOf,
      calendar: CalendarScope.of(context),
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

/// Records gathered under a heading that folds away, as «يحتاج انتباهك»
/// does: [title], [count], «إخفاء» or «عرض», all one button; then [child].
class CollapsibleGroup extends StatelessWidget {
  const CollapsibleGroup({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      // The same surface as «يحتاج انتباهك»: both gather cards under a
      // heading that folds, so they are one thing to the eye.
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceFold,
        border: Border.all(color: AppSemanticColors.accentLeaf),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GroupHeader(
            title: title,
            expanded: expanded,
            onToggle: onToggle,
            count: count,
          ),
          ExpandReveal(
            open: expanded,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one filter of a history: a round button, without words, that opens
/// a menu of the months that have records and who recorded. Filled once
/// something is chosen; what is chosen is read out whole — «الكل»,
/// «أكتوبر 2026، لينا».
class HistoryFilters extends StatefulWidget {
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

  @override
  State<HistoryFilters> createState() => _HistoryFiltersState();
}

class _HistoryFiltersState extends State<HistoryFilters> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final String label = historyFilterLabel(
      context,
      widget.filter,
      people: widget.people,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      // Hidden while its menu is open: one piece of glass.
      child: Builder(
        builder: (BuildContext anchor) => Opacity(
          opacity: _menuOpen ? 0 : 1,
          child: GlassFilterButton(
            label: label,
            active: widget.filter != HistoryFilter.all,
            onPressed: () => _open(anchor, label),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext anchor, String label) async {
    setState(() => _menuOpen = true);
    final String? chosen = await showGlassMenu<String>(
      anchorContext: anchor,
      semanticLabel: label,
      anchorContent: GlassFilterButton.mark,
      sections: historyFilterSections(
        context,
        months: widget.months,
        people: widget.people,
        filter: widget.filter,
      ),
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (chosen == null) return;
    widget.onChanged(chooseInHistory(widget.filter, chosen));
  }
}

/// The key a month is chosen by; empty means «كل الشهور».
String historyMonthKey(DateTime? month) =>
    month == null ? '' : month.toIso8601String();

/// The groups of the history menu: the months that have records, then who
/// recorded. A value is its group's letter and its key, so one menu can
/// answer both questions («m:2026-10-01…», «p:lina»).
List<List<GlassMenuItem<String>>> historyFilterSections(
  BuildContext context, {
  required List<DateTime> months,
  required Map<String, String> people,
  required HistoryFilter filter,
}) {
  final String month = historyMonthKey(filter.month);
  final String person = filter.person ?? '';
  return <List<GlassMenuItem<String>>>[
    <GlassMenuItem<String>>[
      GlassMenuItem<String>(
        value: 'm:',
        label: context.tr('history.all_months'),
        selected: month.isEmpty,
      ),
      for (final DateTime value in months)
        GlassMenuItem<String>(
          value: 'm:${historyMonthKey(value)}',
          label: formatMonth(context, value),
          selected: historyMonthKey(value) == month,
        ),
    ],
    <GlassMenuItem<String>>[
      GlassMenuItem<String>(
        value: 'p:',
        label: context.tr('history.all_people'),
        selected: person.isEmpty,
      ),
      for (final MapEntry<String, String> entry in people.entries)
        GlassMenuItem<String>(
          value: 'p:${entry.key}',
          label: entry.value,
          selected: entry.key == person,
        ),
    ],
  ];
}

/// [filter] with the menu's [chosen] line: a month or a person.
HistoryFilter chooseInHistory(HistoryFilter filter, String chosen) {
  final String value = chosen.substring(2);
  final String? key = value.isEmpty ? null : value;
  return switch (chosen[0]) {
    'm' => filter.withMonth(key == null ? null : DateTime.parse(key)),
    _ => filter.withPerson(key),
  };
}

/// What the filter says when read out: «الكل», or all that is chosen,
/// «أكتوبر 2026، لينا». A person no longer among [people] (a month read
/// away, a member gone) is left out.
String historyFilterLabel(
  BuildContext context,
  HistoryFilter filter, {
  required Map<String, String> people,
}) {
  final DateTime? month = filter.month;
  final List<String> parts = <String>[
    if (month != null) formatMonth(context, month),
    ?people[filter.person],
  ];
  return parts.isEmpty ? context.tr('history.all') : parts.join('، ');
}
