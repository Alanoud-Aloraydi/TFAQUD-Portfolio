import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/device_zone.dart';
import 'package:app/features/account/data/datasources/profile_remote_data_source.dart';
import 'package:app/features/account/domain/repositories/profile_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// Data layer implementation of [ProfileRepository].
///
/// Flow: `ProfileUseCase` → this repository →
/// [BaseProfileRemoteDataSource]. Turns any thrown network error into a
/// [Failure] whose message key the page can show.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._deviceZone);

  final BaseProfileRemoteDataSource _remote;
  final DeviceZone _deviceZone;

  @override
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) async {
    try {
      await _remote.saveProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        birthDate: birthDate,
        city: city,
        // The city's zone, as a new patient's: Saudi Arabia's for a city of
        // the list, this phone's for one typed by hand.
        timeZone: city == null
            ? null
            : SaudiCities.zoneOf(city) ?? await _deviceZone.current(),
      );
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
