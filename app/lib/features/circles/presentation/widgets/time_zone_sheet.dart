import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_list.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_names.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_search_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Opens the sheet that picks the zone where the patient lives: every IANA
/// zone, searchable. Returns the confirmed zone, or null when closed.
Future<String?> showTimeZoneSheet(BuildContext context, {String? selected}) {
  return showGlassSheet<String>(
    context,
    title: context.tr('circles.time_zone_sheet_title'),
    builder: (BuildContext context) => TimeZoneSheet(selected: selected),
  );
}

/// The content of the zone sheet: a search field, the list of zones and
/// the confirm button, like the city sheet. A tap on a zone only marks it; the button returns it.
class TimeZoneSheet extends StatefulWidget {
  const TimeZoneSheet({super.key, this.selected});

  final String? selected;

  @override
  State<TimeZoneSheet> createState() => _TimeZoneSheetState();
}

class _TimeZoneSheetState extends State<TimeZoneSheet> {
  late String? _selected = widget.selected;
  final List<String> _all = placeTimeZones();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String wanted = _query.trim().toLowerCase().replaceAll(' ', '_');
    final List<String> zones = <String>[
      for (final String zone in _all)
        if (zone.toLowerCase().contains(wanted)) zone,
    ];
    // The glass sheet draws the title and stays above the keyboard.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TimeZoneSearchField(
          onChanged: (String value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        TimeZoneList(
          zones: zones,
          selected: _selected,
          onSelected: (String zone) => setState(() => _selected = zone),
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: context.tr('circles.time_zone_confirm'),
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
