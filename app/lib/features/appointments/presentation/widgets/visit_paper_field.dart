import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One text of «ورقة الزيارة» to fill in: its heading ([titleKey]) over a
/// field of two to four lines, holding at most [limit] characters.
class VisitPaperField extends StatelessWidget {
  const VisitPaperField({
    super.key,
    required this.titleKey,
    required this.controller,
    required this.limit,
  });

  final String titleKey;
  final TextEditingController controller;
  final int limit;

  @override
  Widget build(BuildContext context) => InsetGroup(
    header: context.tr(titleKey),
    children: <Widget>[
      InsetBlock(
        child: Padding(
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
        ),
      ),
    ],
  );
}
