import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/repositories/home_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class HomeUseCase {
  HomeUseCase(this._repository);

  final HomeRepositoryDomain _repository;
  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();

  /// Fires when the list of circles of the account changed (a circle was
  /// created, renamed or left). Every open home screen loads the list again.
  /// The value is the circle to select afterwards, or null to keep the
  /// selection.
  Stream<String?> get changes => _changes.stream;

  void notifyCirclesChanged({String? select}) {
    if (!_changes.isClosed) _changes.add(select);
  }

  Future<Result<HomeEntity, Failure>> getHome() => _repository.getHome();

  String? selectedCircle(String accountId) =>
      _repository.selectedCircle(accountId);

  Future<Result<void, Failure>> selectCircle(
    String accountId,
    String circleId,
  ) => _repository.selectCircle(accountId, circleId);
}
