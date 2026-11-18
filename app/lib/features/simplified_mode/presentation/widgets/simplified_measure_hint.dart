import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_field.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// What to type next, under the number, in red once a reading was refused.
Widget simplifiedMeasureHint(
  BuildContext context,
  SimplifiedMeasureForm form,
  MeasurementKind kind,
) => Text(
  context.tr(form.errorKey ?? _hintKey(form, kind)),
  textAlign: TextAlign.center,
  style: SimplifiedStyle.text(
    SimplifiedStyle.body,
    color: form.errorKey == null
        ? SimplifiedColors.muted
        : SimplifiedColors.danger,
    weight: AppTextTheme.medium,
  ),
);

String _hintKey(SimplifiedMeasureForm form, MeasurementKind kind) =>
    kind == MeasurementKind.glucose
    ? 'simplified_mode.type_glucose'
    : form.upperOrLower == SimplifiedMeasureField.upper
    ? 'simplified_mode.type_upper'
    : 'simplified_mode.type_lower';
