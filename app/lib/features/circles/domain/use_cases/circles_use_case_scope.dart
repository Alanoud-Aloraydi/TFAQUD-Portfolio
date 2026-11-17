import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';

/// What every part of the circles use case asks through.
mixin CirclesUseCaseScope {
  CirclesRepositoryDomain get repository;
}
