import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

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
