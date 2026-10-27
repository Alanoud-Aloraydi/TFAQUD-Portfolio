import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/circles/domain/saudi_cities.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    isScrollControlled: true,
    builder: (BuildContext context) =>
        CitySheet(selected: selected, titleKey: titleKey),
  );
}

/// A search field, the list of cities and the confirm button. A tap on a city
/// only marks it; the confirm button returns it.
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
    final List<String> cities = SaudiCities.search(_query);
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
            const SizedBox(height: 12),
            TextField(
              onChanged: (String value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.tr('circles.city_search'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: listHeight,
              child: cities.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('circles.city_none_found'),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: cities.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                      itemBuilder: (BuildContext context, int index) {
                        final String city = cities[index];
                        final bool chosen = city == _selected;
                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: chosen ? AppColors.brand : AppColors.ink3,
                          ),
                          title: Text(
                            city,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: chosen
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: chosen
                              ? const Icon(Icons.check, color: AppColors.brand)
                              : null,
                          onTap: () => setState(() => _selected = city),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
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
