import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One of the three boxes of the «تعديل ورقة الزيارة» sheet, with its own
/// [limit] on how much can be written in it.
Widget visitPaperInput(
  BuildContext context,
  TextEditingController controller,
  int limit,
) => Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: TextField(
    controller: controller,
    maxLength: limit,
    inputFormatters: [CodePointLengthFormatter(limit)],
    minLines: 2,
    maxLines: 4,
    textAlign: TextAlign.start,
    decoration: InputDecoration(
      hintText: context.tr('appointments.visit_empty'),
      border: InputBorder.none,
      counterText: '',
    ),
  ),
);
