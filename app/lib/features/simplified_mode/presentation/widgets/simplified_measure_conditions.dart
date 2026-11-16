import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_note.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «ظروف القياس»: what it is for, the chips, and the note field once
/// «أخرى» is among them.
Widget simplifiedMeasureConditions(
  BuildContext context,
  SimplifiedMeasureForm form, {
  required MeasurementKind kind,
  required VoidCallback onChanged,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '${context.tr('simplified_mode.conditions')} ',
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          TextSpan(
            text: context.tr('simplified_mode.optional'),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ],
      ),
    ),
    Text(
      context.tr('simplified_mode.choose_many'),
      style: SimplifiedStyle.text(SimplifiedStyle.caption),
    ),
    const SizedBox(height: 10),
    simplifiedMeasureChips(context, form, kind: kind, onChanged: onChanged),
    if (form.conditions.contains('other')) ...<Widget>[
      const SizedBox(height: 12),
      simplifiedMeasureNote(context, form),
    ],
  ],
);
