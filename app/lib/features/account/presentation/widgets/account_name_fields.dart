import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/loading/skeleton_card.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The account's first, last and display names, one row each, with
/// «هذا الحقل مطلوب» under a name left empty after a save.
class AccountNameFields extends StatelessWidget {
  const AccountNameFields({
    super.key,
    required this.first,
    required this.last,
    required this.display,
    required this.requiredError,
    required this.onChanged,
  });

  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final String? Function(TextEditingController name) requiredError;

  /// Called when any of the names is typed in.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // The three names, each a row like «اسم العرض».
      LabeledTextField(
        label: context.tr('onboarding.first_name'),
        controller: first,
        maxLength: NameLimits.name,
        errorText: requiredError(first),
        onChanged: (_) => onChanged(),
      ),
      const SizedBox(height: AppSpacing.md),
      LabeledTextField(
        label: context.tr('onboarding.last_name'),
        controller: last,
        maxLength: NameLimits.name,
        errorText: requiredError(last),
        onChanged: (_) => onChanged(),
      ),
      const SizedBox(height: AppSpacing.md),
      LabeledTextField(
        label: context.tr('account.display_name'),
        controller: display,
        maxLength: NameLimits.displayName,
        errorText: requiredError(display),
        onChanged: (_) => onChanged(),
      ),
    ],
  );
}

/// The account page while it loads (design system Skeleton): the card with
/// the round initial and the name, «بياناتي» with its three rows, the note,
/// and the card of the two account actions. The page already has its header
/// and side padding around the body.
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonSurface(
          child: Row(
            children: <Widget>[
              SkeletonCircle(size: 48),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLine(widthFactor: 0.5, height: 20)),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.25, height: 16),
        SizedBox(height: AppSpacing.md),
        SkeletonDetailsCard(rows: 3),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.8, height: 12),
        SizedBox(height: AppSpacing.md),
        SkeletonDetailsCard(rows: 2),
      ],
    );
  }
}
