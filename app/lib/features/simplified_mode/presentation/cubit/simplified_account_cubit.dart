import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Loads the name, photo, and circle shown by the simplified account
/// screen. Composes the existing home data instead of its own endpoint.
@injectable
class SimplifiedAccountCubit extends Cubit<SimplifiedAccountState> {
  SimplifiedAccountCubit(this._home) : super(const SimplifiedAccountState());

  final HomeUseCase _home;

  Future<void> load() async {
    emit(const SimplifiedAccountState());
    final result = await _home.getHome();
    if (isClosed) return;
    if (result.isError() || result.tryGetSuccess()!.circles.isEmpty) {
      emit(
        const SimplifiedAccountState(status: SimplifiedAccountStatus.failure),
      );
      return;
    }
    final home = result.tryGetSuccess()!;
    emit(
      SimplifiedAccountState(
        status: SimplifiedAccountStatus.ready,
        displayName: home.displayName,
        avatarCode: home.avatarCode,
        circleId: home.circles.first.id,
      ),
    );
  }
}
