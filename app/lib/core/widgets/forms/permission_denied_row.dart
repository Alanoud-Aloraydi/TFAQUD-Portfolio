import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/open_settings_action.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Why a feature cannot work, with the one way back: the phone's own
/// Settings. iOS asks for a permission once, so a refusal is only undone
/// there, and a message without this button leaves the person hunting.
class PermissionDeniedRow extends StatelessWidget {
  const PermissionDeniedRow({super.key, required this.messageKey});

  /// The sentence above the button, such as
  /// `circle_overview.calendar_access_denied`.
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.sm,
        start: AppSpacing.inset,
        end: AppSpacing.inset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr(messageKey),
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.statusWarning,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: OpenSettingsAction(),
          ),
        ],
      ),
    );
  }
}
