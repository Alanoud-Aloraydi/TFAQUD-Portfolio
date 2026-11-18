import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:equatable/equatable.dart';

/// Every range of one patient, and the conditions in their medical file
/// that chose them (`diabetes`, `hypertension`).
class NormalRanges extends Equatable {
  const NormalRanges({required this.conditions, required this.ranges});

  final List<String> conditions;
  final List<NormalRange> ranges;

  /// The range a reading of [kind] in meal [state] is judged by: glucose
  /// fasting or before a meal by the fasting one, any other by the one
  /// after a meal.
  NormalRange? of(MeasurementKind kind, [String? state]) {
    final String? group = kind == MeasurementKind.bp
        ? null
        : normalRangeState(state);
    return ranges
        .where((range) => range.kind == kind && range.state == group)
        .firstOrNull;
  }

  factory NormalRanges.fromJson(Map<String, dynamic> json) => NormalRanges(
    conditions: (json['conditions'] as List<dynamic>).cast<String>(),
    ranges: [
      for (final dynamic item in json['ranges'] as List<dynamic>)
        NormalRange.fromJson(item as Map<String, dynamic>),
    ],
  );

  @override
  List<Object?> get props => [conditions, ranges];
}
