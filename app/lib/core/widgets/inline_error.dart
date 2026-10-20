import 'package:app/core/constants/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// An error line with an icon (color is never the only signal).
/// [messageKey] is a key in assets/translations.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.dangerInk,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(messageKey),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.dangerInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
