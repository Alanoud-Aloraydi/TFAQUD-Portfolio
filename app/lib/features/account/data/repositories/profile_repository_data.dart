import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/account/data/datasources/profile_remote_data_source.dart';
import 'package:app/features/account/domain/repositories/profile_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

/// Data layer implementation of [ProfileRepositoryDomain].
///
/// Flow: `ProfileUseCase` → this repository →
/// [BaseProfileRemoteDataSource]. Turns any thrown network error into a
/// [Failure] whose message key the page can show.
@LazySingleton(as: ProfileRepositoryDomain)
class ProfileRepositoryData implements ProfileRepositoryDomain {
  ProfileRepositoryData(this._remote);

  final BaseProfileRemoteDataSource _remote;

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
      );
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
