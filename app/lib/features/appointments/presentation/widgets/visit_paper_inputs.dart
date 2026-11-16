import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/appointments/presentation/widgets/visit_paper_input.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The three headed boxes of the «تعديل ورقة الزيارة» sheet, in order.
List<Widget> visitPaperInputs(
  BuildContext context, {
  required TextEditingController summary,
  required TextEditingController recommendations,
  required TextEditingController followUp,
}) => [
  InsetGroup(
    header: context.tr('appointments.visit_summary'),
    children: [InsetBlock(child: visitPaperInput(context, summary, 2000))],
  ),
  const SizedBox(height: AppSpacing.md),
  InsetGroup(
    header: context.tr('appointments.visit_recommendations'),
    children: [
      InsetBlock(child: visitPaperInput(context, recommendations, 2000)),
    ],
  ),
  const SizedBox(height: AppSpacing.md),
  InsetGroup(
    header: context.tr('appointments.visit_follow_up'),
    children: [InsetBlock(child: visitPaperInput(context, followUp, 500))],
  ),
];
