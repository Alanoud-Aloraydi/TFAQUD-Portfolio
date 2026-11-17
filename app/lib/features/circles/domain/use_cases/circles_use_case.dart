import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/circles/domain/use_cases/circle_creation_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circle_members_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circle_requests_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case_scope.dart';
import 'package:app/features/circles/domain/use_cases/medical_file_use_case.dart';
import 'package:injectable/injectable.dart';

/// The circle reads and writes the application is allowed to make.
@lazySingleton
class CirclesUseCase
    with
        CirclesUseCaseScope,
        CircleMembersUseCase,
        CircleCreationUseCase,
        CircleRequestsUseCase,
        MedicalFileUseCase {
  CirclesUseCase(this.repository);

  @override
  final CirclesRepositoryDomain repository;
}
