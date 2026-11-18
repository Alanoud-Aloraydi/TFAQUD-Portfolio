import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «حفظ القراءة», off while it is being saved ([onPressed] null).
class ReadingSaveButton extends StatelessWidget {
  const ReadingSaveButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(context.tr('measurements.save_reading')),
      ),
    ),
  );
}
