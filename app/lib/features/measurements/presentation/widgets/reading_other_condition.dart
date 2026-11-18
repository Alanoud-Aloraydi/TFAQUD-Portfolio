import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «أخرى» of a reading's conditions, in the reader's own words.
class ReadingOtherCondition extends StatelessWidget {
  const ReadingOtherCondition({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) => LabeledTextField(
    label: context.tr('measurements.other_condition'),
    helperText: context.tr('measurements.other_condition_hint'),
    controller: controller,
    maxLength: maxLength,
    textInputAction: TextInputAction.done,
    onChanged: (_) {},
  );
}
