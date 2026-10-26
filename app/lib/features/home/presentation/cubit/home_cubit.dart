import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._home) : super(const HomeState());

  final HomeUseCase _home;
  int _revision = 0;
  bool _selecting = false;

  Future<void> load() async {
    final revision = ++_revision;
    emit(const HomeState());
    final result = await _home.getHome();
    if (isClosed || revision != _revision) return;
    await result.when((data) => _loaded(data, revision), (failure) async {
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

  Future<void> _loaded(HomeEntity data, int revision) async {
    if (!data.profileComplete) {
      emit(const HomeState(status: HomeStatus.onboarding));
      return;
    }
    final saved = _home.selectedCircle(data.accountId);
    final selected = data.circles.any((circle) => circle.id == saved)
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
