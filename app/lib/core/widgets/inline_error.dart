import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
          // The icon is as tall as the text's 20 line, so it sits on it.
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: AppSizes.iconSmall,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(messageKey),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
