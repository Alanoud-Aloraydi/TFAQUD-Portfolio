import 'package:app/core/errors/auth_failures.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading the home data: the first load with its loading page, and the
/// quiet reload that keeps the screen the user is on.
mixin HomeLoading on Cubit<HomeState>, HomeScope, HomeLoaded {
  /// Loads the home data and shows the loading page first. [select] is a
  /// circle to select once the data arrives, when it is in the list.
  Future<void> load({String? select}) async {
    final revision = ++this.revision;
    emit(const HomeState());
    final result = await home.getHome();
    if (isClosed || revision != this.revision) return;
    await result.when((data) => showLoaded(data, revision, select), (
      failure,
    ) async {
      final ended =
          failure is UnauthorizedFailure || failure is SessionExpiredFailure;
      emit(
        HomeState(
          status: ended ? HomeStatus.signIn : HomeStatus.failure,
          messageKey: failure.messageKey,
        ),
      );
    });
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
    final revision = ++this.revision;
    final result = await home.getHome();
    if (isClosed || revision != this.revision) return;
    await result.when((data) => showLoaded(data, revision, select), (
      failure,
    ) async {
      final ended =
          failure is UnauthorizedFailure || failure is SessionExpiredFailure;
      if (ended) {
        emit(
          HomeState(status: HomeStatus.signIn, messageKey: failure.messageKey),
        );
      }
    });
  }
}

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
