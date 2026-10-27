import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._home) : super(const HomeState()) {
    _changes = _home.changes.listen((select) => refresh(select: select));
  }

  final HomeUseCase _home;
  late final StreamSubscription<String?> _changes;
  int _revision = 0;
  bool _selecting = false;

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }

  /// Loads the home data and shows the loading page first. [select] is a
  /// circle to select once the data arrives, when it is in the list.
  Future<void> load({String? select}) async {
    final revision = ++_revision;
    emit(const HomeState());
    final result = await _home.getHome();
    if (isClosed || revision != _revision) return;
    await result.when(
      (data) => _loaded(data, revision, select),
      (failure) async {
        final ended =
            failure is UnauthorizedFailure || failure is SessionExpiredFailure;
        emit(
          HomeState(
            status: ended ? HomeStatus.signIn : HomeStatus.failure,
            messageKey: failure.messageKey,
          ),
        );
      },
    );
  }

  /// Loads the home data again without leaving the screen the user is on.
  /// [load] shows the loading page first, so it is only used for the first
  /// load and for a retry. This one is used when the app comes back to the
  /// front and when the list of circles changes: the tabs, the forms and the
  /// selected circle stay as they are until the new data arrives.
  ///
  /// A failure keeps what is on screen, except when the server says the
  /// sign-in ended. [select] is a circle to select once the data arrives.
  Future<void> refresh({String? select}) async {
    if (state.status != HomeStatus.ready) {
      await load(select: select);
      return;
    }
    final revision = ++_revision;
    final result = await _home.getHome();
    if (isClosed || revision != _revision) return;
    await result.when(
      (data) => _loaded(data, revision, select),
      (failure) async {
        final ended =
            failure is UnauthorizedFailure || failure is SessionExpiredFailure;
        if (ended) {
          emit(
            HomeState(
              status: HomeStatus.signIn,
              messageKey: failure.messageKey,
            ),
          );
        }
      },
    );
  }

  Future<void> _loaded(
    HomeEntity data,
    int revision,
    String? preferred,
  ) async {
    if (!data.profileComplete) {
      emit(const HomeState(status: HomeStatus.onboarding));
      return;
    }
    final saved = _home.selectedCircle(data.accountId);
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
      await _home.selectCircle(data.accountId, selected);
      if (isClosed || revision != _revision) return;
    }
    emit(
      HomeState(
        status: HomeStatus.ready,
        data: data,
        selectedCircleId: selected,
      ),
    );
  }

  Future<void> selectCircle(String id) async {
    final data = state.data;
    if (_selecting ||
        data == null ||
        state.selectedCircleId == id ||
        !data.circles.any((circle) => circle.id == id)) {
      return;
    }
    _selecting = true;
    final revision = _revision;
    final result = await _home.selectCircle(data.accountId, id);
    _selecting = false;
    if (isClosed || revision != _revision) return;
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
