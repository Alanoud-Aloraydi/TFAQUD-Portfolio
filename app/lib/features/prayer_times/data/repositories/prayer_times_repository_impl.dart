import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/time_zones.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// Sends prayer times requests to the API.
class PrayerTimesRemoteDataSource {
  const PrayerTimesRemoteDataSource(this._client);

  final DioClient _client;

  Future<PrayerDayModel> getToday(String circleId) async {
    final response = await _client.get(CircleEndpoints.prayerTimes(circleId));
    return PrayerDayModel.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Maps prayer day data between the API and app.
class PrayerDayModel {
  const PrayerDayModel(this.day);

  final PrayerDay day;

  factory PrayerDayModel.fromJson(Map<String, dynamic> json) {
    final values = json['timings'] as Map<String, dynamic>;
    final times = <Prayer, String>{
      Prayer.fajr: values['Fajr'] as String,
      Prayer.dhuhr: values['Dhuhr'] as String,
      Prayer.asr: values['Asr'] as String,
      Prayer.maghrib: values['Maghrib'] as String,
      Prayer.isha: values['Isha'] as String,
    };
    if (times.values.any(
      (value) => !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value),
    )) {
      throw const FormatException('Invalid prayer time');
    }
    return PrayerDayModel(
      PrayerDay(
        date: DateTime.parse(json['date'] as String),
        city: json['city'] as String,
        times: times,
        timeZone: json['timezone'] as String? ?? defaultPatientZone,
      ),
    );
  }
}

/// The server owns the prayer times.
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this._remote);

  final PrayerTimesRemoteDataSource _remote;

  @override
  Future<Result<PrayerDay, Failure>> getToday(String circleId) async {
    try {
      return Success((await _remote.getToday(circleId)).day);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
