import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_values.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// What «تسجيل قياس» shows: a spinner while it loads, the reason and
/// «حاول مرة أخرى» after a failure, «لا يوجد قياس» when there is nothing
/// to record, and otherwise the form with the last readings under it.
List<Widget> simplifiedMeasureBody(
  BuildContext context,
  SimplifiedMeasurementState state,
  SimplifiedMeasureForm form, {
  required VoidCallback onChanged,
}) {
  final MeasurementKind? kind = form.kind;
  return switch (state.status) {
    SimplifiedMeasurementStatus.loading => const <Widget>[LoadingNote()],
    SimplifiedMeasurementStatus.failure => <Widget>[
      simplifiedMeasureMessage(context, state.messageKey ?? 'error.unknown'),
      SimplifiedButton(
        label: context.tr('simplified_mode.try_again'),
        onPressed: context.read<SimplifiedMeasurementCubit>().load,
      ),
    ],
    SimplifiedMeasurementStatus.ready when kind == null => <Widget>[
      simplifiedMeasureMessage(context, 'simplified_mode.no_target'),
    ],
    SimplifiedMeasurementStatus.ready => <Widget>[
      ...simplifiedMeasureFormRows(
        context,
        state,
        form,
        kind!,
        onChanged: onChanged,
      ),
      const SizedBox(height: SimplifiedStyle.gap),
      SimplifiedRecentReadings(
        readings: state.recent,
        kind: kind,
        now: PatientClockScope.of(context).now(),
      ),
    ],
  };
}

/// A plain sentence in place of the form: a failure, or nothing to record.
Widget simplifiedMeasureMessage(BuildContext context, String key) => Text(
  context.tr(key),
  style: SimplifiedStyle.text(
    SimplifiedStyle.body,
    color: SimplifiedColors.ink,
  ),
);

/// Which number the keypad types into.
enum SimplifiedMeasureField { glucose, upper, lower }
