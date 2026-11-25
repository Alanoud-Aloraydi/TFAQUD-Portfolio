import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_list.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The way back, the page's name, and the pencil «تعديل» that opens the
/// edit page once the file is loaded.
class MedicalFileHeader extends StatelessWidget {
  const MedicalFileHeader({
    super.key,
    required this.canEdit,
    required this.onEdit,
  });

  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      BackLink(
        onPressed: context.canPop()
            ? () => context.pop()
            : () => context.go(Routes.circle),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                context.tr('circles.file_title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          if (canEdit)
            EditAction(
              onPressed: onEdit,
              tooltip: context.tr('circles.file_edit_title'),
            ),
        ],
      ),
    ],
  );
}

/// The three sheets the medical file picks its answers from. Each keeps the
/// saved answer selected, and leaves it alone when the sheet is dismissed.
Future<void> pickBirthDate(
  BuildContext context,
  MedicalFileEditState state,
  MedicalFileEditCubit cubit,
) async {
  // A patient with an account holds it, so is 15 or older.
  final DateTime? picked = await showBirthDateSheet(
    context,
    selected: state.birthDate,
    youngestAge: (state.file?.patient.hasAccount ?? false)
        ? BirthDateRules.youngestAccountAge
        : 0,
  );
  if (picked != null) cubit.birthDateChanged(picked);
}

Future<void> pickCity(
  BuildContext context,
  MedicalFileEditState state,
  MedicalFileEditCubit cubit,
) async {
  final String? picked = await showCitySheet(
    context,
    selected: state.city,
    titleKey: 'circles.patient_city_sheet_title',
  );
  if (picked != null) cubit.cityChanged(picked);
}

Future<void> pickTimeZone(
  BuildContext context,
  MedicalFileEditState state,
  MedicalFileEditCubit cubit,
) async {
  final String? picked = await showTimeZoneSheet(
    context,
    selected: state.timeZone,
  );
  if (picked != null) cubit.timeZoneChanged(picked);
}

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

/// The search field over the zones. The zone names are Latin, so it reads
/// left to right whatever the app's language.
class TimeZoneSearchField extends StatelessWidget {
  const TimeZoneSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: context.tr('circles.time_zone_search'),
        prefixIcon: const Icon(ActionIcons.search),
      ),
    );
  }
}
