
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/onboarding/domain/entities/onboarding_entity.dart';

import 'package:app/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:app/features/onboarding/data/models/onboarding_model.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';

@LazySingleton(as: OnboardingRepositoryDomain)
class OnboardingRepositoryData implements OnboardingRepositoryDomain{
  final BaseOnboardingRemoteDataSource remoteDataSource;


  OnboardingRepositoryData(this.remoteDataSource);

@override
  Future<Result<OnboardingEntity, Failure>> getOnboarding() async {
    try {
      final response = await remoteDataSource.getOnboarding();
      return Success(response.toEntity());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
