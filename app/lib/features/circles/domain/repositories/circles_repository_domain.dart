import 'package:app/features/circles/domain/repositories/circle_creation_repository.dart';
import 'package:app/features/circles/domain/repositories/circle_members_repository.dart';
import 'package:app/features/circles/domain/repositories/circle_requests_repository.dart';
import 'package:app/features/circles/domain/repositories/medical_file_repository.dart';

/// The circle operations the application needs, whatever provides them.
abstract class CirclesRepositoryDomain
    implements
        CircleMembersRepository,
        CircleCreationRepository,
        CircleRequestsRepository,
        MedicalFileRepository {}
