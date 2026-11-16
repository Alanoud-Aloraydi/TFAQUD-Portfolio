import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:equatable/equatable.dart';

/// Holds the normal ranges of one patient while they load.
class MeasurementRangesState extends Equatable {
  const MeasurementRangesState({
    this.loading = true,
    this.ranges,
    this.errorKey,
  });

  final bool loading;

  /// Null until read, or when reading failed.
  final NormalRanges? ranges;
  final String? errorKey;

  @override
  List<Object?> get props => [loading, ranges, errorKey];
}
