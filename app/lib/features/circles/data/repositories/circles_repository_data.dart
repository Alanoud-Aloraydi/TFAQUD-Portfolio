import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: CirclesRepositoryDomain)
class CirclesRepositoryData implements CirclesRepositoryDomain {
  CirclesRepositoryData(this._remote);

  final BaseCirclesRemoteDataSource _remote;

  @override
  Future<Result<AccountSummary, Failure>> getAccount() async {
    try {
      return Success((await _remote.getAccount()).toEntity());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) async {
    try {
      final created = await _remote.createSelfCircle(
        NewSelfCircleModel(circle),
      );
      return Success(created.toEntity());
    } catch (error) {
      return Error(_circleFailure(error));
    }
  }

  /// The API codes that have their own text; every other error is read by
  /// [FailureExceptions].
  Failure _circleFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.alreadyHasCircle => const AlreadyHasCircleFailure(),
      ApiErrorCodes.profileIncomplete => const ProfileIncompleteFailure(),
      ApiErrorCodes.invalidBirthDate => const InvalidBirthDateFailure(),
      _ => FailureExceptions.getException(error),
    };
  }
}
