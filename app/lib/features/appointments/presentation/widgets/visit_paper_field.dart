import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One text of «ورقة الزيارة» to fill in, in the design system's form row
/// as every text field of the app: its name ([titleKey]), then up to four
/// lines that a tap anywhere on the row starts typing, holding at most
/// [limit] characters.
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
    children: <Widget>[
      InsetTextRow(
        label: context.tr(titleKey),
        controller: controller,
        onChanged: (_) {},
        hint: context.tr('common.optional'),
        maxLength: limit,
        maxLines: 4,
      ),
    ],
  );
}
