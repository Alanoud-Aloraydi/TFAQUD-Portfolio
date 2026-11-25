import 'package:app/core/errors/failure.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// The prayer times the application is allowed to read.
class PrayerTimesUseCase {
  const PrayerTimesUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Result<PrayerDay, Failure>> getToday(String circleId) =>
      _repository.getToday(circleId);
}
