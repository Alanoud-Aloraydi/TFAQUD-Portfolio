import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_call.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_creating.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:app/features/circles/presentation/cubit/create_circle_call.dart'
    show maxCustomNameLength;

/// Keeps the answers of the page that creates a circle and creates the circle
/// of its [flow].
class CreateCircleCubit extends Cubit<CreateCircleState>
    with
        CreateCircleScope,
        CreateCircleAccount,
        CreateCircleAnswers,
        CreateCircleResult,
        CreateCircleCreating {
  /// [request] is the request the patient agreed to, and is needed for the
  /// [CircleFlow.approved] flow only; it travels with the route. The patient
  /// names that circle on the page, as they would their own.
  CreateCircleCubit(this.circles, this.home, {required this.flow, this.request})
    : super(
        CreateCircleState(
          accountLoad: flow == CircleFlow.patient
              ? AccountLoad.notNeeded
              : AccountLoad.loading,
        ),
      );

  @override
  final CirclesUseCase circles;

  @override
  final HomeUseCase home;

  @override
  final CircleFlow flow;

  @override
  final ReceivedCircleRequest? request;
}

/// Reading the account the circle is created from.
mixin CreateCircleAccount on Cubit<CreateCircleState>, CreateCircleScope {
  /// Loads the account: its name, whether it already has a circle of its own
  /// care, and the birth date and city onboarding saved. The page works
  /// without it (it then asks for the birth date and city), so a failure
  /// shows a message and a retry; the server still refuses a second circle.
  /// Does nothing for [CircleFlow.patient], whose patient is someone else.
  Future<void> loadAccount() async {
    if (flow == CircleFlow.patient) return;
    emit(state.copyWith(accountLoad: AccountLoad.loading));
    final result = await circles.getAccount();
    if (isClosed) return;
    result.when(
      (account) {
        emit(state.copyWith(account: account, accountLoad: AccountLoad.loaded));
        // The home screen may not show that circle yet; it loads again.
        if (account.hasOwnCircle) home.notifyCirclesChanged();
      },
      (failure) => emit(
        state.copyWith(
          accountLoad: AccountLoad.failed,
          sessionEnded: endedSession(failure),
        ),
      ),
    );
  }
}

/// What the person answers on the page. Every answer clears the message of
/// the try before it, so what is shown belongs to what is on screen now.
mixin CreateCircleAnswers on Cubit<CreateCircleState>, CreateCircleScope {
  void choosePreset(NamePreset preset) {
    emit(state.copyWith(namePreset: preset, clearError: true));
  }

  void customNameChanged(String value) {
    emit(state.copyWith(customName: value, clearError: true));
  }

  void birthDateChanged(DateTime value) {
    emit(state.copyWith(birthDate: value, clearError: true));
  }

  void cityChanged(String value) {
    emit(state.copyWith(city: value, clearError: true));
  }

  void patientFirstNameChanged(String value) {
    emit(state.copyWith(patientFirstName: value, clearError: true));
  }

  void patientLastNameChanged(String value) {
    emit(state.copyWith(patientLastName: value, clearError: true));
  }
}
