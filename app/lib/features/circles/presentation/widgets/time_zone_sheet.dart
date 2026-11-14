import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// The zone as a row shows it: its IANA name with spaces, «Europe / London».
/// The names stay as the IANA database writes them: there is no Arabic
/// name for each of the world's zones.
String timeZoneName(String zone) =>
    zone.replaceAll('_', ' ').replaceAll('/', ' / ');

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

  /// Every place zone of the database, by name («Etc/GMT+3» style offsets
  /// are left out: they have no DST and no place).
  static List<String> get zones {
    ensureTimeZones();
    return tz.timeZoneDatabase.locations.keys
        .where((String name) => name.contains('/') && !name.startsWith('Etc/'))
        .toList()
      ..sort();
  }

  @override
  State<TimeZoneSheet> createState() => _TimeZoneSheetState();
}

class _TimeZoneSheetState extends State<TimeZoneSheet> {
  late String? _selected = widget.selected;
  final List<String> _all = TimeZoneSheet.zones;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
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
        TextField(
          onChanged: (String value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: context.tr('circles.time_zone_search'),
            prefixIcon: const Icon(AppIcons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.4,
          child: ListView.builder(
            itemCount: zones.length,
            itemBuilder: (BuildContext context, int index) {
              final String zone = zones[index];
              final bool chosen = zone == _selected;
              return ListTile(
                title: Text(
                  timeZoneName(zone),
                  textDirection: TextDirection.ltr,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: chosen
                        ? AppTextTheme.bold
                        : AppTextTheme.regular,
                  ),
                ),
                trailing: chosen
                    ? const Icon(
                        AppIcons.check,
                        color: AppSemanticColors.textPrimary,
                      )
                    : null,
                onTap: () => setState(() => _selected = zone),
              );
            },
          ),
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
