import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/attention_mark.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The yellow «!» and «أكمل الملف الطبي» beside it.
class MedicalAlertTitle extends StatelessWidget {
  const MedicalAlertTitle({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const AttentionMark(),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          context.tr('medical_alert.title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}
