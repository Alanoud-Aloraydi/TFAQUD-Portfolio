import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';

/// Where measurements are kept, with the normal ranges the patient's
/// readings are judged by. The plan form and the reading sheet read the
/// ranges through this, so they never depend on how they are stored.
abstract class MeasurementRepository implements MeasurementsRepositoryDomain {
  /// The normal ranges [circleId]'s patient's readings are judged by, and
  /// the conditions of the medical file that chose them.
  Future<NormalRanges> ranges(String circleId);
}
