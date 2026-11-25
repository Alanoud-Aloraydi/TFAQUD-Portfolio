import 'dart:async';

import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_member_actions.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_acting.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads the selected circle independently of the home shell, and invites,
/// resends, cancels and leaves for it.
///
/// The patient card shows facts from the medical file. When the file is
/// saved on its own pages (pushed over this tab), the card shows the new
/// answers at once, without reading the file again.
class CircleOverviewCubit extends Cubit<CircleOverviewState>
    with
        CircleOverviewScope,
        CircleOverviewLoading,
        CircleOverviewSaves,
        CircleOverviewActing,
        CircleMemberActions {
  CircleOverviewCubit(this.circles, this.circleId, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const CircleOverviewState()) {
    _saves = circles.medicalFileSaves(circleId).listen(takeSaved);
    // The patient card and the member row show the patient's avatar; a
    // saved photo or avatar anywhere reloads it too, not just the screen
    // that saved it.
    _photoChanges?.addListener(_onPhotoChanged);
  }

  @override
  final CirclesUseCase circles;

  @override
  final String circleId;

  final Listenable? _photoChanges;
  late final StreamSubscription<MedicalFile> _saves;

  void _onPhotoChanged() => unawaited(load());

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    await _saves.cancel();
    return super.close();
  }
}

/// Taking in a medical file saved on the pages pushed over this tab, so the
/// patient card shows the new answers at once.
mixin CircleOverviewSaves on Cubit<CircleOverviewState>, CircleOverviewScope {
  void takeSaved(MedicalFile file) {
    saveCount++;
    lastSaved = file;
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
    final int revision = ++this.revision;
    final result = await circles.getCircleOverview(circleId);
    if (isClosed ||
        revision != this.revision ||
        result.isError() ||
        state.status != CircleOverviewStatus.ready) {
      return;
    }
    emit(state.copyWith(overview: result.tryGetSuccess()));
  }
}

/// What the circle tab is bound to, shared by everything it does.
mixin CircleOverviewScope on Cubit<CircleOverviewState> {
  CirclesUseCase get circles;

  /// The circle shown.
  String get circleId;

  /// How many files were saved elsewhere since this tab opened, and the
  /// last one. A read that was on its way during a save is older than it.
  int saveCount = 0;
  MedicalFile? lastSaved;

  /// Counts the reads of the circle; only the newest one is shown.
  int revision = 0;
}
