import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «ملاحظة» of the reading sheet: a line of the recorder's own words.
class ReadingNoteGroup extends StatelessWidget {
  const ReadingNoteGroup({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: [
      InsetTextRow(
        label: context.tr('measurements.note'),
        controller: controller,
        onChanged: (_) {},
        maxLength: 250,
      ),
    ],
  );
}
