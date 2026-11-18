import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «إلغاء الطلب», full width, in the error red.
class SentRequestCancelButton extends StatelessWidget {
  const SentRequestCancelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        // Cancelling a request cannot be undone: the error red.
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppSemanticColors.statusError,
          side: const BorderSide(color: AppSemanticColors.borderControlBase),
        ),
        child: Text(context.tr('circles.cancel_request')),
      ),
    );
  }
}
