import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Defines the supported circle overview status values.
enum CircleOverviewStatus { loading, ready, failure }

/// What the circle tab shows: the circle, the facts of its medical file, and
/// whether a change of the members is on its way.
class CircleOverviewState extends Equatable {
  const CircleOverviewState({
    this.status = CircleOverviewStatus.loading,
    this.overview,
    this.medicalFile,
    this.errorKey,
    this.acting = false,
  });

  final CircleOverviewStatus status;
  final CircleOverview? overview;

  /// Null when the file could not be read: the card leaves its facts out.
  final MedicalFile? medicalFile;

  /// Why the load failed: a key in assets/translations.
  final String? errorKey;

  /// True while an invitation, a resend, a cancel or the leave is on its
  /// way; another one is refused until it ends.
  final bool acting;

  CircleOverviewState copyWith({
    CircleOverviewStatus? status,
    CircleOverview? overview,
    MedicalFile? medicalFile,
    String? errorKey,
    bool? acting,
  }) {
    return CircleOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      medicalFile: medicalFile ?? this.medicalFile,
      errorKey: errorKey ?? this.errorKey,
      acting: acting ?? this.acting,
    );
  }

  @override
  List<Object?> get props => [status, overview, medicalFile, errorKey, acting];
}

/// Loads the selected circle independently of the home shell, and invites,
/// resends, cancels and leaves for it.
///
/// The patient card shows facts from the medical file. When the file is
/// saved on its own pages (pushed over this tab), the card shows the new
/// answers at once, without reading the file again.
class CircleOverviewCubit extends Cubit<CircleOverviewState> {
  CircleOverviewCubit(this._circles, this.circleId, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const CircleOverviewState()) {
    _saves = _circles.medicalFileSaves(circleId).listen(_saved);
    // The patient card and the member row show the patient's avatar; a
    // saved photo or avatar anywhere reloads it too, not just the screen
    // that saved it.
    _photoChanges?.addListener(_onPhotoChanged);
  }

  final CirclesUseCase _circles;
  final String circleId;
  final Listenable? _photoChanges;

  void _onPhotoChanged() => unawaited(load());

  late final StreamSubscription<MedicalFile> _saves;

  /// How many files were saved elsewhere since this tab opened, and the
  /// last one. A read that was on its way during a save is older than it.
  int _saveCount = 0;
  MedicalFile? _lastSaved;

  /// Counts the reads of the circle; only the newest one is shown.
  int _revision = 0;

  void _saved(MedicalFile file) {
    _saveCount++;
    _lastSaved = file;
    final CircleOverviewState current = state;
    if (isClosed || current.status != CircleOverviewStatus.ready) return;
    emit(current.copyWith(medicalFile: file));
    // A new name, birth date or city is also in the line under the circle's
    // name, which comes with the circle: read the circle again quietly.
    if (current.medicalFile?.patient != file.patient) {
      unawaited(_refreshCircle());
    }
  }

  Future<void> _refreshCircle() async {
    final int revision = ++_revision;
    final result = await _circles.getCircleOverview(circleId);
    if (isClosed ||
        revision != _revision ||
        result.isError() ||
        state.status != CircleOverviewStatus.ready) {
      return;
    }
    emit(state.copyWith(overview: result.tryGetSuccess()));
  }

  /// Reads the circle and its medical file. The first read and a retry after
  /// a failure show the loading state; a later read keeps the tab on screen.
  Future<void> load() async {
    final int revision = ++_revision;
    final int saves = _saveCount;
    if (state.status == CircleOverviewStatus.failure) {
      emit(const CircleOverviewState());
    }
    // The circle and its medical file are read at the same time. The file
    // only adds the facts on the patient card: when it cannot be read, the
    // tab still shows the circle and its members, and the medical file page
    // says why when it is opened.
    final (result, fileResult) = await (
      _circles.getCircleOverview(circleId),
      _circles.getMedicalFile(circleId),
    ).wait;
    if (isClosed || revision != _revision) return;
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
        acting: state.acting,
      ),
    );
  }

  /// Invites [nationalNumber] to manage the circle. Returns an error key, or
  /// null once the invitation is saved and the list read again.
  Future<String?> invite(String nationalNumber) async {
    if (!SaudiMobile.isValid(nationalNumber)) {
      return 'circle_overview.phone_invalid';
    }
    return _act(
      () => _circles.inviteManager(
        circleId,
        SaudiMobile.international(nationalNumber),
      ),
    );
  }

  /// Sends a pending invitation again. Returns an error key, or null.
  Future<String?> resendInvitation(String invitationId) =>
      _act(() => _circles.resendManagerInvitation(circleId, invitationId));

  /// Cancels a pending invitation. Returns an error key, or null.
  Future<String?> cancelInvitation(String invitationId) =>
      _act(() => _circles.cancelManagerInvitation(circleId, invitationId));

  Future<String?> setMemberEditAccess(
    String accountId, {
    required bool canEdit,
  }) => _act(
    () => _circles.setMemberEditAccess(circleId, accountId, canEdit: canEdit),
  );

  Future<String?> removeMember(String accountId) =>
      _act(() => _circles.removeMember(circleId, accountId));

  /// Leaves the circle; [confirmDelete] agrees that the circle is deleted
  /// ([CircleOverview.leaveDeletesCircle]). Returns an error key, or null
  /// once the person is out. The circle is not read again after a success:
  /// the person can no longer read it.
  Future<String?> leave({required bool confirmDelete}) => _act(
    () => _circles.leaveCircle(circleId, confirmDelete: confirmDelete),
    reload: false,
  );

  /// Runs one change of the members at a time: a call while another is on
  /// its way (or before the circle is read) sends nothing and returns null;
  /// the page disables its buttons while [CircleOverviewState.acting].
  /// After a success (when [reload]), and after a failure that means the
  /// tab is out of date, the circle is read again.
  Future<String?> _act(
    Future<Result<void, Failure>> Function() call, {
    bool reload = true,
  }) async {
    if (state.acting || state.status != CircleOverviewStatus.ready) {
      return null;
    }
    emit(state.copyWith(acting: true));
    final Result<void, Failure> result = await call();
    if (isClosed) return null;
    emit(state.copyWith(acting: false));
    final Failure? failure = result.tryGetError();
    if ((failure == null && reload) ||
        failure is InvitationUnavailableFailure ||
        failure is LeaveDeletesCircleFailure) {
      await load();
    }
    return failure?.messageKey;
  }

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    await _saves.cancel();
    return super.close();
  }
}
