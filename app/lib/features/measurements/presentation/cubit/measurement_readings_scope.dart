import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the readings of one circle are bound to, shared by reading them
/// and by saving one.
mixin MeasurementReadingsScope on Cubit<MeasurementReadingsState> {
  MeasurementsUseCase get measurements;

  /// The circle and the patient's days read last.
  String? readCircleId;
  DateTime? readFrom;
  DateTime? readTo;

  /// The circle read last; null before the first load.
  String? get circleId => readCircleId;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// True while a reading or a follow-up is saving: a second tap saves
  /// nothing.
  bool writing = false;

  /// Reads the last load again, quietly: what is shown stays meanwhile.
  Future<void> reload();
}
