import 'dart:async';

import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_scope.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
