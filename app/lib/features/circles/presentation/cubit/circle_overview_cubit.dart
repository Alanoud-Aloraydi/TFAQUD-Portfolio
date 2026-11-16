import 'dart:async';

import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_member_actions.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_acting.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_loading.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_saves.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_scope.dart';
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
