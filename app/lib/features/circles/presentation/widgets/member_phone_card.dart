import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A member's number, or the line that says a patient without an account
/// has none in the app.
class MemberPhoneCard extends StatelessWidget {
  const MemberPhoneCard({super.key, required this.phone});

  final String? phone;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? number = phone;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppSemanticColors.surfaceContent,
          shape: AppRadius.shape(AppRadius.m, side: AppSurfaces.edge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.tr('circle_overview.member_phone'),
                style: text.bodySmall?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (number != null)
                // A number reads left to right inside Arabic text.
                Text(
                  SaudiMobile.display(number),
                  textDirection: TextDirection.ltr,
                  style: text.titleMedium,
                )
              else
                Text(
                  context.tr('circle_overview.member_no_phone'),
                  style: text.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
