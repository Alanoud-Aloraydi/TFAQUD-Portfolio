import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/prayer_times/data/prayer_day_model.dart';

class PrayerTimesRemoteDataSource {
  const PrayerTimesRemoteDataSource(this._client);

  final DioClient _client;

  Future<PrayerDayModel> getToday(String circleId) async {
    final response = await _client.get(ApiEndpoints.prayerTimes(circleId));
    return PrayerDayModel.fromJson(response.data as Map<String, dynamic>);
  }
}
