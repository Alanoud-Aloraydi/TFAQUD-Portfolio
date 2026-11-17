import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
