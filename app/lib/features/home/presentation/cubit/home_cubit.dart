import 'dart:async';

import 'package:app/app/services/shown_circle_clock.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_loading.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates home actions and UI state.
///
/// [shownClock], when given, follows the selected circle, so every page
/// reads that patient's clock (see [ShownCircleClock]).
class HomeCubit extends Cubit<HomeState>
    with HomeScope, HomeLoaded, HomeLoading, HomeCircleSelection {
  HomeCubit(this.home, [Listenable? photoChanges, this._shownClock])
    : _photoChanges = photoChanges,
      super(const HomeState()) {
    _changes = home.changes.listen((select) => refresh(select: select));
    // The circle switcher shows the patient's avatar; a saved photo or
    // avatar anywhere reloads it too, not just the screen that saved it.
    _photoChanges?.addListener(_onPhotoChanged);
  }

  @override
  final HomeUseCase home;

  final Listenable? _photoChanges;
  final ShownCircleClock? _shownClock;
  late final StreamSubscription<String?> _changes;

  void _onPhotoChanged() => unawaited(refresh());

  /// Every state with a selected circle shows that patient's clock.
  @override
  void emit(HomeState state) {
    super.emit(state);
    final String? zone = state.selectedCircle?.timeZone;
    if (zone != null) _shownClock?.show(zone);
  }

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    await _changes.cancel();
    return super.close();
  }
}

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

/// What the home shell is read with, shared by everything it does.
mixin HomeScope on Cubit<HomeState> {
  HomeUseCase get home;

  /// Counts the reads of the home data; only the newest one is shown.
  int revision = 0;
}
