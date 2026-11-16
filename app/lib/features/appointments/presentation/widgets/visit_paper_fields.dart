import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The three written answers of a visit paper, read only.
Widget visitPaperGroup(BuildContext context, VisitPaper? paper) => InsetGroup(
  children: [
    InsetBlock(
      child: visitPaperField(
        context,
        'appointments.visit_summary',
        paper?.summary,
      ),
    ),
    InsetBlock(
      child: visitPaperField(
        context,
        'appointments.visit_recommendations',
        paper?.recommendations,
      ),
    ),
    InsetBlock(
      child: visitPaperField(
        context,
        'appointments.visit_follow_up',
        paper?.followUp,
      ),
    ),
  ],
);

/// One stop for the reader: the heading and its answer together.
Widget visitPaperField(BuildContext context, String key, String? value) =>
    MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(key), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value?.isNotEmpty == true
                ? value!
                : context.tr('appointments.visit_empty'),
          ),
        ],
      ),
    );
