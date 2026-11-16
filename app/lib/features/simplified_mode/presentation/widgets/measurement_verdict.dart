import 'package:app/features/measurements/domain/normal_range.dart';

/// A reading's level in the words and the icon every page uses for it.
class MeasurementVerdict {
  const MeasurementVerdict(this.label, this.level);

  final String label;
  final MeasurementLevel level;
}
