import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';

/// What a typed reading becomes when it is saved.
extension SimplifiedReadingDraft on SimplifiedReading {
  /// The reading as it was measured at [measuredAt].
  MeasurementReadingDraft toDraft(DateTime measuredAt) {
    return MeasurementReadingDraft(
      kind: kind,
      outcome: 'read',
      measuredAt: measuredAt,
      valueOne: valueOne,
      valueTwo: valueTwo,
      conditions: conditions,
      otherCondition: note,
    );
  }
}
