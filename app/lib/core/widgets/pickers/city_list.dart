import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

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
