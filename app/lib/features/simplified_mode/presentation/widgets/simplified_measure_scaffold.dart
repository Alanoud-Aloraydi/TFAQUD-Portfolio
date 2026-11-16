import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_reading.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «تسجيل قياس» as a page: the body of the moment, and «حفظ القياس» at
/// the bottom once there is a form to save.
Widget simplifiedMeasurePage(
  BuildContext context,
  SimplifiedMeasurementState state,
  SimplifiedMeasureForm form, {
  required VoidCallback onChanged,
  required VoidCallback onSave,
}) {
  final MeasurementKind? kind = form.kind;
  final bool ready =
      state.status == SimplifiedMeasurementStatus.ready && kind != null;
  return SimplifiedPage(
    title: context.tr('simplified_mode.measure_title'),
    backKey: 'simplified_mode.close',
    // A failure or a missing target is read too, not only the form.
    footer: ready
        ? SimplifiedButton(
            label: context.tr('simplified_mode.save_reading'),
            onPressed: state.saving || simplifiedMeasureReading(form) == null
                ? null
                : onSave,
          )
        : null,
    children: simplifiedMeasureBody(context, state, form, onChanged: onChanged),
  );
}
