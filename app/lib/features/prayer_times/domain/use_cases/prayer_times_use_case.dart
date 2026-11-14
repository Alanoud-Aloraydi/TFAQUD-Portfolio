import 'package:app/core/errors/failure.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository_domain.dart';
import 'package:multiple_result/multiple_result.dart';

/// The prayer times the application is allowed to read.
class PrayerTimesUseCase {
  const PrayerTimesUseCase(this._repository);

  final PrayerTimesRepositoryDomain _repository;

  Future<Result<PrayerDay, Failure>> getToday(String circleId) =>
      _repository.getToday(circleId);
}
