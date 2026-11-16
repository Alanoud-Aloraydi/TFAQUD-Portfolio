import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/core/widgets/navigation/history_filter_sections.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// The one filter of a history: a capsule that opens a menu of two
/// groups, the months that have records and who recorded. Two capsules
/// stood side by side before, each hiding half the answer; one says it
/// whole — «الكل», «أكتوبر 2026», «لينا», or both.
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

  /// What the capsule says; a person no longer among [people] (a month
  /// read away, a member gone) leaves their half out.
  String _label(BuildContext context) {
    final DateTime? month = widget.filter.month;
    final List<String> parts = <String>[
      if (month != null) formatMonth(context, month),
      ?widget.people[widget.filter.person],
    ];
    return parts.isEmpty ? context.tr('history.all') : parts.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final String label = _label(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      // Hidden while its menu is open: one piece of glass.
      child: Builder(
        builder: (BuildContext anchor) => Opacity(
          opacity: _menuOpen ? 0 : 1,
          child: GlassCapsuleButton(
            label: label,
            semanticLabel: label,
            icon: CupertinoIcons.slider_horizontal_3,
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
      anchorContent: Text(label),
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
    final String value = chosen.substring(2);
    widget.onChanged(
      chosen.startsWith('m:')
          ? widget.filter.withMonth(
              value.isEmpty ? null : DateTime.parse(value),
            )
          : widget.filter.withPerson(value.isEmpty ? null : value),
    );
  }
}
