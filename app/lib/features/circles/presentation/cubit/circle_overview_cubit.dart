import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CircleOverviewStatus { loading, ready, failure }

class CircleOverviewState extends Equatable {
  const CircleOverviewState({
    this.status = CircleOverviewStatus.loading,
    this.overview,
    this.medicalFile,
    this.errorKey,
  });

  final CircleOverviewStatus status;
  final CircleOverview? overview;
  final MedicalFile? medicalFile;
  final String? errorKey;

  @override
  List<Object?> get props => [status, overview, medicalFile, errorKey];
}

/// Loads the selected circle independently of the home shell.
///
/// The patient card shows facts from the medical file. When the file is
/// saved on its own pages (pushed over this tab), the card shows the new
/// answers at once, without reading the file again.
class CircleOverviewCubit extends Cubit<CircleOverviewState> {
  CircleOverviewCubit(this._circles, this.circleId)
    : super(const CircleOverviewState()) {
    _saves = _circles.medicalFileSaves(circleId).listen(_saved);
  }

  final CirclesUseCase _circles;
  final String circleId;

  late final StreamSubscription<MedicalFile> _saves;

  /// How many files were saved elsewhere since this tab opened, and the
  /// last one. A read that was on its way during a save is older than it.
  int _saveCount = 0;
  MedicalFile? _lastSaved;

  void _saved(MedicalFile file) {
    _saveCount++;
    _lastSaved = file;
    final CircleOverviewState current = state;
    if (isClosed || current.status != CircleOverviewStatus.ready) return;
    emit(
      CircleOverviewState(
        status: CircleOverviewStatus.ready,
        overview: current.overview,
        medicalFile: file,
      ),
    );
    // A new name, birth date or city is also in the line under the circle's
    // name, which comes with the circle: read the circle again quietly.
    if (current.medicalFile?.patient != file.patient) {
      unawaited(_refreshCircle());
    }
  }

  Future<void> _refreshCircle() async {
    final result = await _circles.getCircleOverview(circleId);
    final CircleOverviewState current = state;
    if (isClosed ||
        result.isError() ||
        current.status != CircleOverviewStatus.ready) {
      return;
    }
    emit(
      CircleOverviewState(
        status: CircleOverviewStatus.ready,
        overview: result.tryGetSuccess()!,
        medicalFile: current.medicalFile,
      ),
    );
  }

  Future<void> load() async {
    final int saves = _saveCount;
    // The circle and its medical file are read at the same time. The file
    // only adds the facts on the patient card: when it cannot be read, the
    // tab still shows the circle and its members, and the medical file page
    // says why when it is opened.
    final (result, fileResult) = await (
      _circles.getCircleOverview(circleId),
      _circles.getMedicalFile(circleId),
    ).wait;
    if (isClosed) return;
    if (result.isError()) {
      emit(
        CircleOverviewState(
          status: CircleOverviewStatus.failure,
          errorKey: result.tryGetError()!.messageKey,
        ),
      );
      return;
    }
    emit(
      CircleOverviewState(
        status: CircleOverviewStatus.ready,
        overview: result.tryGetSuccess()!,
        medicalFile: saves == _saveCount
            ? fileResult.tryGetSuccess()
            : _lastSaved,
      ),
    );
  }

  /// Returns an error key, or null after the invitation is saved.
  Future<String?> invite(String nationalNumber) async {
    if (!RegExp(r'^5[0-9]{8}$').hasMatch(nationalNumber)) {
      return 'circle_overview.phone_invalid';
    }
    final result = await _circles.inviteManager(
      circleId,
      '+966$nationalNumber',
    );
    if (isClosed) return null;
    String? errorKey;
    result.when((_) {}, (Failure failure) => errorKey = failure.messageKey);
    if (errorKey != null) return errorKey;
    await load();
    return null;
  }

  Future<String?> resendInvitation(String invitationId) async {
    final result = await _circles.resendManagerInvitation(
      circleId,
      invitationId,
    );
    if (isClosed) return null;
    if (result.isError()) return result.tryGetError()!.messageKey;
    await load();
    return null;
  }

  Future<String?> cancelInvitation(String invitationId) async {
    final result = await _circles.cancelManagerInvitation(
      circleId,
      invitationId,
    );
    if (isClosed) return null;
    if (result.isError()) return result.tryGetError()!.messageKey;
    await load();
    return null;
  }

  Future<String?> leave({required bool confirmDelete}) async {
    final result = await _circles.leaveCircle(
      circleId,
      confirmDelete: confirmDelete,
    );
    if (isClosed) return null;
    return result.isError() ? result.tryGetError()!.messageKey : null;
  }

  @override
  Future<void> close() async {
    await _saves.cancel();
    return super.close();
  }
}
