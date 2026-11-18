import 'package:app/features/measurements/domain/measurement_level.dart';
import 'package:app/features/measurements/domain/normal_band.dart';
import 'package:equatable/equatable.dart';

/// The range one reading is judged by: its table ([profile]: `general`,
/// `diabetes` or `hypertension`), its meal state ([state]: `fasting` or
/// `after_meal` for glucose, null for blood pressure) and its normal band.
class ReadingRange extends Equatable {
  const ReadingRange({required this.profile, required this.normal, this.state});

  final String profile;
  final String? state;
  final NormalBand normal;

  /// The `normal_range` of a reading; null for a skip, or from a server
  /// before fixed ranges.
  static ReadingRange? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return ReadingRange(
      profile: value['profile'] as String,
      state: value['state'] as String?,
      normal: NormalBand.fromJson(value, level: MeasurementLevel.normal),
    );
  }

  @override
  List<Object?> get props => [profile, state, normal];
}
