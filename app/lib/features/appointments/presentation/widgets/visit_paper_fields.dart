import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
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

/// The three texts of «ورقة الزيارة» while they are filled in: each with
/// its heading's key, the most characters it holds, and its controller.
class VisitPaperTexts {
  VisitPaperTexts(VisitPaper? paper)
    : fields = <(String, int, TextEditingController)>[
        _field('appointments.visit_summary', 2000, paper?.summary),
        _field(
          'appointments.visit_recommendations',
          2000,
          paper?.recommendations,
        ),
        _field('appointments.visit_follow_up', 500, paper?.followUp),
      ];

  final List<(String, int, TextEditingController)> fields;

  static (String, int, TextEditingController) _field(
    String key,
    int limit,
    String? text,
  ) => (key, limit, TextEditingController(text: text));

  /// What «حفظ» sends.
  VisitPaperDraft get draft => VisitPaperDraft(
    summary: fields[0].$3.text,
    recommendations: fields[1].$3.text,
    followUp: fields[2].$3.text,
  );

  void dispose() {
    for (final (_, _, TextEditingController text) in fields) {
      text.dispose();
    }
  }
}
