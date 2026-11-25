import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/pickers/city_list.dart';
import 'package:app/core/widgets/pickers/city_search_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:app/core/widgets/pickers/city_search_field.dart'
    show cityMaxLength;

/// Opens the "اختر مدينتك" sheet (CREAT-01B). Returns the confirmed city, or
/// null when the sheet is closed without confirming. [titleKey] is the
/// translation key of the title; the circle of another person asks for the
/// city of the patient.
Future<String?> showCitySheet(
  BuildContext context, {
  String? selected,
  String titleKey = 'circles.city_sheet_title',
}) {
  return showGlassSheet<String>(
    context,
    title: context.tr(titleKey),
    builder: (BuildContext context) => CitySheet(selected: selected),
  );
}

/// The content of the city sheet: a search field, the list of cities and
/// the confirm button. A tap on a city
/// only marks it; the confirm button returns it. A city not in the list (a
/// patient anywhere in the world) is offered as typed, first in the list.
class CitySheet extends StatefulWidget {
  const CitySheet({super.key, this.selected});

  final String? selected;

  @override
  State<CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<CitySheet> {
  late String? _selected = widget.selected;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String typed = _query.trim().replaceAll(RegExp(r'\s+'), ' ');
    final List<String> cities = <String>[
      // The name as typed, unless the list has it already.
      if (typed.isNotEmpty && !SaudiCities.all.contains(typed)) typed,
      ...SaudiCities.search(_query),
    ];
    final double listHeight = MediaQuery.sizeOf(context).height * 0.4;
    // The glass sheet draws the title and stays above the keyboard.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CitySearchField(
          onChanged: (String value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        CityList(
          cities: cities,
          selected: _selected,
          height: listHeight,
          onSelected: (String city) => setState(() => _selected = city),
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: context.tr('circles.city_confirm'),
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
