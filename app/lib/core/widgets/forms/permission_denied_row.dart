import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Why a feature cannot work, under its switch. The way back is the switch
/// itself: turned on, it says so and leaves for the phone's Settings
/// (`leaveForSettings`), so no second button repeats it here.
class PermissionDeniedRow extends StatelessWidget {
  const PermissionDeniedRow({super.key, required this.messageKey});

  /// The sentence, such as `circle_overview.calendar_access_denied`.
  final String messageKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: AppSpacing.sm,
      start: AppSpacing.inset,
      end: AppSpacing.inset,
    ),
    child: Text(
      context.tr(messageKey),
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppSemanticColors.statusWarning),
    ),
  );
}
