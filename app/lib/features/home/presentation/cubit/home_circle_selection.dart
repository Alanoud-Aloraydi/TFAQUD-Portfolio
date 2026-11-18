import 'package:app/features/home/presentation/cubit/home_scope.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Choosing which circle the home shell shows, and keeping that choice.
mixin HomeCircleSelection on Cubit<HomeState>, HomeScope {
  bool _selecting = false;

  Future<void> selectCircle(String id) async {
    final data = state.data;
    if (_selecting ||
        data == null ||
        state.selectedCircleId == id ||
        !data.circles.any((circle) => circle.id == id)) {
      return;
    }
    _selecting = true;
    final revision = this.revision;
    final result = await home.selectCircle(data.accountId, id);
    _selecting = false;
    if (isClosed || revision != this.revision) return;
    result.when(
      (_) {
        emit(
          HomeState(status: HomeStatus.ready, data: data, selectedCircleId: id),
        );
      },
      (failure) {
        emit(
          HomeState(
            status: HomeStatus.ready,
            data: data,
            selectedCircleId: state.selectedCircleId,
            messageKey: failure.messageKey,
          ),
        );
      },
    );
  }
}
