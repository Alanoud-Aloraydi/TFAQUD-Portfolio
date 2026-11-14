import 'package:app/core/errors/failure.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:multiple_result/multiple_result.dart';

/// The prayer times of a circle's patient, wherever they come from.
abstract class PrayerTimesRepositoryDomain {
  /// The times of the patient's today, in the patient's own zone.
  Future<Result<PrayerDay, Failure>> getToday(String circleId);
}
