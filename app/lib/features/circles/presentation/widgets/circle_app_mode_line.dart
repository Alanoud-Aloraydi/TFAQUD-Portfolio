import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «وضع التطبيق: **تفصيلي**» behind the card icon: the label in the
/// supporting colour, the [value] in the text's own.
class CircleAppModeLine extends StatelessWidget {
  const CircleAppModeLine({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(
          PeopleIcons.idCard,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.textSupporting,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '${context.tr('circle_overview.app_mode')} '),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppSemanticColors.textPrimary,
                    fontWeight: AppTextTheme.semibold,
                  ),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
