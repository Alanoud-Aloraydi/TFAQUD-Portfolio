import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «وضع التطبيق: **تفصيلي**», and under it why it cannot be changed here.
/// A patient who does not use the app says so in the same row and the same
/// words, rather than the row disappearing: the family still needs to know
/// why that person never signs in.
class CircleAppModeRow extends StatelessWidget {
  const CircleAppModeRow({
    super.key,
    required this.mode,
    required this.usesApp,
  });

  final CircleAppMode? mode;

  /// Whether the patient has an account of their own.
  final bool usesApp;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String value = context.tr(
      !usesApp
          ? 'circle_overview.no_app'
          : mode == CircleAppMode.simplified
          ? 'circle_overview.simplified'
          : 'circle_overview.detailed',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAppModeLine(value: value),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSizes.iconSmall + AppSpacing.sm,
          ),
          child: Text(
            context.tr(
              usesApp
                  ? 'circle_overview.mode_note'
                  : 'circle_overview.profile_summary',
            ),
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }
}

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
