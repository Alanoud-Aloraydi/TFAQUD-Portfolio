import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// The longest city name the server keeps (`City` in circles/inputs.py).
const int cityMaxLength = 60;

/// The search field at the top of the city sheet.
class CitySearchField extends StatelessWidget {
  const CitySearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      // The longest city the server keeps.
      inputFormatters: const <TextInputFormatter>[
        CodePointLengthFormatter(cityMaxLength),
      ],
      decoration: InputDecoration(
        hintText: context.tr('circles.city_search'),
        prefixIcon: const Icon(ActionIcons.search),
      ),
    );
  }
}

/// The scrolling list of cities in the city sheet, [height] tall.
class CityList extends StatelessWidget {
  const CityList({
    super.key,
    required this.cities,
    required this.selected,
    required this.height,
    required this.onSelected,
  });

  final List<String> cities;
  final String? selected;
  final double height;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      // Never empty: a name that matches nothing is offered as
      // typed.
      child: ListView.separated(
        itemCount: cities.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          final String city = cities[index];
          return CityTile(
            city: city,
            chosen: city == selected,
            onTap: () => onSelected(city),
          );
        },
      ),
    );
  }
}

/// One city in the city sheet's list: a pin, the name and a check when it is
/// the marked one.
class CityTile extends StatelessWidget {
  const CityTile({
    super.key,
    required this.city,
    required this.chosen,
    required this.onTap,
  });

  final String city;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(
        ScheduleIcons.mapPin,
        color: chosen
            ? AppSemanticColors.textPrimary
            : context.tokens.textSecondary,
      ),
      title: Text(
        city,
        style: text.bodyLarge?.copyWith(
          fontWeight: chosen ? AppTextTheme.bold : AppTextTheme.regular,
        ),
      ),
      trailing: chosen
          ? const Icon(ActionIcons.check, color: AppSemanticColors.textPrimary)
          : null,
      onTap: onTap,
    );
  }
}
