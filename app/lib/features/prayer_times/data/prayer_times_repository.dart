import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:multiple_result/multiple_result.dart';

/// Provides prayer times data operations.
class PrayerTimesRepository {
  const PrayerTimesRepository(this._remote);

  final PrayerTimesRemoteDataSource _remote;

  Future<Result<PrayerDay, Failure>> getToday(String circleId) async {
    try {
      return Success((await _remote.getToday(circleId)).day);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
