import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:equatable/equatable.dart';

/// The readings on screen, with the days they cover.
class MeasurementReadingsState extends Equatable {
  const MeasurementReadingsState({
    this.status = MeasurementLoadStatus.initial,
    this.readings = const [],
    this.errorKey,
  });

  final MeasurementLoadStatus status;
  final List<MeasurementReading> readings;
  final String? errorKey;

  @override
  List<Object?> get props => [status, readings, errorKey];
}
