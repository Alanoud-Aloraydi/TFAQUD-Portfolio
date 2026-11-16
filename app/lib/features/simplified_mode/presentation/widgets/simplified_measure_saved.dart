import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_reading.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Saves what the patient typed, or puts the reason under the number and
/// stays. [onChanged] redraws the screen.
Future<void> saveSimplifiedMeasure(
  BuildContext context,
  SimplifiedMeasureForm form,
  VoidCallback onChanged,
) async {
  final SimplifiedReading? reading = simplifiedMeasureReading(form);
  if (reading == null || !reading.isValid) {
    form.errorKey = simplifiedInvalidReadingKey(reading);
    onChanged();
    return;
  }
  final bool saved = await context.read<SimplifiedMeasurementCubit>().save(
    reading,
  );
  if (!saved || !context.mounted) return;
  _openDone(context, reading);
}

/// Refreshes «اليوم» and goes to «تم، شكرًا» with the level the server
/// judged the saved reading at.
void _openDone(BuildContext context, SimplifiedReading reading) {
  final MeasurementLevel? level = context
      .read<SimplifiedMeasurementCubit>()
      .state
      .saved
      ?.level;
  unawaited(context.read<SimplifiedModeCubit>().load());
  context.pushReplacement(
    Routes.simplifiedDone,
    extra: reading.kind == MeasurementKind.glucose
        ? SimplifiedDoneMessage.glucose(reading.valueOne, level: level)
        : SimplifiedDoneMessage.bloodPressure(
            reading.valueOne,
            reading.valueTwo!,
            level: level,
          ),
  );
}
