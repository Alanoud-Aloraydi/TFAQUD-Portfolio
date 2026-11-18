import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_scope.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Showing the home data once it has arrived, with the circle to select.
mixin HomeLoaded on Cubit<HomeState>, HomeScope {
  Future<void> showLoaded(
    HomeEntity data,
    int revision,
    String? preferred,
  ) async {
    if (!data.profileComplete) {
      emit(const HomeState(status: HomeStatus.onboarding));
      return;
    }
    final saved = home.selectedCircle(data.accountId);
    bool inList(String? id) =>
        id != null && data.circles.any((circle) => circle.id == id);
    // The circle asked for, then the saved one, then the first of the list.
    final selected = inList(preferred)
        ? preferred
        : inList(saved)
        ? saved
        : data.circles.firstOrNull?.id;
    if (selected != null && selected != saved) {
      // A preference write failure must not hide authorized circles.
      await home.selectCircle(data.accountId, selected);
      if (isClosed || revision != this.revision) return;
    }
    emit(
      HomeState(
        status: HomeStatus.ready,
        data: data,
        selectedCircleId: selected,
      ),
    );
  }
}
