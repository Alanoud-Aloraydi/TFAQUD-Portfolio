import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/widgets/navigation/glass_filter_button.dart';
import 'package:app/core/widgets/navigation/history_filter_choice.dart';
import 'package:app/core/widgets/navigation/history_filter_sections.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:flutter/widgets.dart';

/// The one filter of a history: a round button, without words, that opens
/// a menu of its groups: the [kinds] of record when there are two or more,
/// the months that have records and who recorded. Filled once something
/// is chosen; what is chosen is read out whole — «الكل», «ضغط الدم»,
/// «أكتوبر 2026، لينا».
class HistoryFilters extends StatefulWidget {
  const HistoryFilters({
    super.key,
    required this.months,
    required this.people,
    required this.filter,
    required this.onChanged,
    this.kinds = const <String, String>{},
  });

  final List<DateTime> months;
  final Map<String, String> people;
  final HistoryFilter filter;
  final ValueChanged<HistoryFilter> onChanged;

  /// The kinds the records have, key to words; empty for one kind only.
  final Map<String, String> kinds;

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
      kinds: widget.kinds,
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
        kinds: widget.kinds,
      ),
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (chosen == null) return;
    widget.onChanged(chooseInHistory(widget.filter, chosen));
  }
}
