import 'package:app/features/circles/presentation/cubit/circle_overview_scope.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading the circle and its medical file together.
mixin CircleOverviewLoading on Cubit<CircleOverviewState>, CircleOverviewScope {
  /// Reads the circle and its medical file. The first read and a retry
  /// after a failure show the loading state; a later read keeps the tab on
  /// screen.
  Future<void> load() async {
    final int revision = ++this.revision;
    final int saves = saveCount;
    if (state.status == CircleOverviewStatus.failure) {
      emit(const CircleOverviewState());
    }
    // The circle and its medical file are read at the same time. The file
    // only adds the facts on the patient card: when it cannot be read, the
    // tab still shows the circle and its members, and the medical file page
    // says why when it is opened.
    final (result, fileResult) = await (
      circles.getCircleOverview(circleId),
      circles.getMedicalFile(circleId),
    ).wait;
    if (isClosed || revision != this.revision) return;
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
        medicalFile: saves == saveCount
            ? fileResult.tryGetSuccess()
            : lastSaved,
        acting: state.acting,
      ),
    );
  }
}
