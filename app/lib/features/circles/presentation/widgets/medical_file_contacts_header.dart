import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «جهات الاتصال في الطوارئ», and the note that says there are none yet.
///
/// Notes outside the cards start 16 in, lined up with the heading and the
/// text inside the cards; the cards and the button reach the edge.
List<Widget> medicalFileContactsHeader(
  BuildContext context, {
  required bool empty,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
      child: Semantics(
        header: true,
        child: Text(
          context.tr('circles.file_contacts_title'),
          style: text.titleMedium,
        ),
      ),
    ),
    const SizedBox(height: AppSpacing.labelGap),
    if (empty) ...<Widget>[
      InsetText(
        context.tr('circles.file_contacts_empty'),
        style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  ];
}
