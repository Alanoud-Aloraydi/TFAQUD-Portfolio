import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «أكمل الآن» inside the yellow box, which opens the edit page.
class MedicalFileFillButton extends StatelessWidget {
  const MedicalFileFillButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppSemanticColors.textPrimary,
      foregroundColor: AppSemanticColors.surfaceContent,
    ),
    icon: const Icon(ActionIcons.pencil, size: AppSizes.iconSmall),
    label: Text(context.tr('medical_alert.fill')),
  );
}
