import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the delete sheet holds: the question, what deleting means, and the
/// two big answers.
Widget simplifiedDeleteSheetBody(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.delete_title'),
            style: SimplifiedStyle.head(26),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('simplified_mode.delete_text'),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    SimplifiedButton(
      label: context.tr('simplified_mode.delete_yes'),
      tone: SimplifiedButtonTone.danger,
      onPressed: () => Navigator.of(context).pop(true),
    ),
    const SizedBox(height: 12),
    SimplifiedButton(
      label: context.tr('simplified_mode.delete_no'),
      tone: SimplifiedButtonTone.quiet,
      onPressed: () => Navigator.of(context).pop(false),
    ),
  ],
);
