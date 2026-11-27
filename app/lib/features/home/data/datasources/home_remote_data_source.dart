import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/time_zones.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:get_storage/get_storage.dart';

/// Sends base home requests to the API.
abstract class BaseHomeRemoteDataSource {
  Future<HomeModel> getHome();
}

/// Sends home requests to the API.
class HomeRemoteDataSource implements BaseHomeRemoteDataSource {
  HomeRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<HomeModel> getHome() async {
    final response = await _client.get(ApiEndpoints.home);
    return HomeModel.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Maps the home API payload without retaining clinical or session data.
class HomeModel {
  const HomeModel(this._entity);

  final HomeEntity _entity;

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>;
    final circles = json['care_circles'] as List<dynamic>;
    return HomeModel(
      HomeEntity(
        accountId: account['id'] as String,
        displayName: account['display_name'] as String?,
        profileComplete: account['profile_complete'] as bool,
        avatarCode: account['avatar_code'] as String?,
        latitude: (account['latitude'] as num?)?.toDouble(),
        longitude: (account['longitude'] as num?)?.toDouble(),
        circles: circles.map((item) {
          final circle = item as Map<String, dynamic>;
          return CareCircleSummary(
            id: circle['id'] as String,
            name: circle['name'] as String,
            canManageMedications:
                circle['can_manage_medications'] as bool? ?? false,
            canManageMeasurements: circle['can_manage_measurements'] as bool?,
            canManageAppointments: circle['can_manage_appointments'] as bool?,
            patientAvatarCode: circle['patient_avatar_code'] as String?,
            isPatient: circle['is_patient'] as bool? ?? true,
            // The leader of a patient without a phone (an account).
            standsInForPatient:
                (circle['is_leader'] as bool? ?? false) &&
                !(circle['patient_has_account'] as bool? ?? true),
            patientName: circle['patient_name'] as String?,
            timeZone: circle['time_zone'] as String? ?? defaultPatientZone,
          );
        }).toList(),
      ),
    );
  }

  HomeEntity toEntity() => _entity;
}

/// Stores circle identifiers per account; authorization always comes from API.
class HomeLocalDataSource {
  HomeLocalDataSource(this._storage);

  final GetStorage _storage;

  String? selectedCircle(String accountId) =>
      _storage.read<String>('home.selected_circle.$accountId');

  Future<void> selectCircle(String accountId, String circleId) =>
      _storage.write('home.selected_circle.$accountId', circleId);
}
