import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «تعديل الرقم» under the code page's title.
class EditPhoneButton extends StatelessWidget {
  const EditPhoneButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppSemanticColors.textPrimary,
        padding: EdgeInsets.zero,
        alignment: AlignmentDirectional.centerStart,
      ),
      child: Text(
        context.tr('auth.edit_phone'),
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: AppSemanticColors.textPrimary),
      ),
    );
  }
}
