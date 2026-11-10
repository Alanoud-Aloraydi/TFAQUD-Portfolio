import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The longest city name the server keeps (`City` in circles/inputs.py).
const int cityMaxLength = 60;

/// Opens the "اختر مدينتك" sheet (CREAT-01B). Returns the confirmed city, or
/// null when the sheet is closed without confirming. [titleKey] is the
/// translation key of the title; the circle of another person asks for the
/// city of the patient.
Future<String?> showCitySheet(
  BuildContext context, {
  String? selected,
  String titleKey = 'circles.city_sheet_title',
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        CitySheet(selected: selected, titleKey: titleKey),
  );
}

/// A search field, the list of cities and the confirm button. A tap on a city
/// only marks it; the confirm button returns it. A city not in the list (a
/// patient anywhere in the world) is offered as typed, first in the list.
class CitySheet extends StatefulWidget {
  const CitySheet({
    super.key,
    this.selected,
    this.titleKey = 'circles.city_sheet_title',
  });

  final String? selected;
  final String titleKey;

  @override
  State<CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<CitySheet> {
  late String? _selected = widget.selected;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String typed = _query.trim().replaceAll(RegExp(r'\s+'), ' ');
    final List<String> cities = <String>[
      // The name as typed, unless the list has it already.
      if (typed.isNotEmpty && !SaudiCities.all.contains(typed)) typed,
      ...SaudiCities.search(_query),
    ];
    final double listHeight = MediaQuery.sizeOf(context).height * 0.4;
    return SafeArea(
      child: Padding(
        // Keeps the sheet above the keyboard while the user searches.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                context.tr(widget.titleKey),
                style: text.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              onChanged: (String value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              // The longest city the server keeps.
              inputFormatters: const <TextInputFormatter>[
                CodePointLengthFormatter(cityMaxLength),
              ],
              decoration: InputDecoration(
                hintText: context.tr('circles.city_search'),
                prefixIcon: const Icon(AppIcons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: listHeight,
              // Never empty: a name that matches nothing is offered as
              // typed.
              child: ListView.separated(
                itemCount: cities.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
                itemBuilder: (BuildContext context, int index) {
                  final String city = cities[index];
                  final bool chosen = city == _selected;
                  return ListTile(
                    leading: Icon(
                      AppIcons.mapPin,
                      color: chosen
                          ? AppSemanticColors.textPrimary
                          : context.tokens.textSecondary,
                    ),
                    title: Text(
                      city,
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
                    onTap: () => setState(() => _selected = city),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: context.tr('circles.city_confirm'),
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}
