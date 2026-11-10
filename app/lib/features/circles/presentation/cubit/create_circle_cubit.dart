import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Keeps the answers of the page that creates a circle and creates the circle
/// of its [flow].
class CreateCircleCubit extends Cubit<CreateCircleState> {
  /// [request] is the request the patient agreed to, and is needed for the
  /// [CircleFlow.approved] flow only; it travels with the route. The patient
  /// names that circle on the page, as they would their own.
  CreateCircleCubit(
    this._circles,
    this._home, {
    required this.flow,
    this.request,
  }) : super(
         CreateCircleState(
           accountLoad: flow == CircleFlow.patient
               ? AccountLoad.notNeeded
               : AccountLoad.loading,
         ),
       );

  final CirclesUseCase _circles;
  final HomeUseCase _home;

  /// Which circle is created: the signed-in person's own, one for a patient
  /// without the app, or the one a patient agreed to.
  final CircleFlow flow;

  /// The request of the [CircleFlow.approved] flow.
  final ReceivedCircleRequest? request;

  /// The longest typed circle name. The API accepts 60; a short name is what
  /// fits in the row of circles at the top of the screen.
  static const int maxCustomNameLength = 30;

  /// Loads the account: its name, whether it already has a circle of its own
  /// care, and the birth date and city onboarding saved. The page works
  /// without it (it then asks for the birth date and city), so a failure
  /// shows a message and a retry; the server still refuses a second circle.
  /// Does nothing for [CircleFlow.patient], whose patient is someone else.
  Future<void> loadAccount() async {
    if (flow == CircleFlow.patient) return;
    emit(state.copyWith(accountLoad: AccountLoad.loading));
    final result = await _circles.getAccount();
    if (isClosed) return;
    result.when(
      (account) {
        emit(state.copyWith(account: account, accountLoad: AccountLoad.loaded));
        // The home screen may not show that circle yet; it loads again.
        if (account.hasOwnCircle) _home.notifyCirclesChanged();
      },
      (failure) => emit(
        state.copyWith(
          accountLoad: AccountLoad.failed,
          sessionEnded: _ended(failure),
        ),
      ),
    );
  }

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

  /// Creates the circle of the [flow]. [presetName] is the text of the chosen
  /// chip, which the page translates; the [CircleFlow.patient] flow names
  /// nothing (the server names it «دائرة» and the patient's first name). A
  /// missing answer marks the fields and sends nothing. A tap while the
  /// account loads, while saving or after the circle was created sends
  /// nothing either. Returns true when the circle was created, so the page
  /// can leave.
  Future<bool> create({String presetName = ''}) async {
    if (state.busy || state.status == CreateStatus.created) return false;
    if (state.alreadyHasCircle) {
      emit(state.copyWith(errorKey: 'circles.already_has_circle'));
      return false;
    }
    final String name = state.namePreset == NamePreset.other
        ? state.customName.trim()
        : presetName.trim();
    final DateTime? birthDate = state.patientBirthDate;
    final String? city = state.patientCity;
    final bool nameMissing = flow == CircleFlow.patient
        ? !state.patientNamesComplete
        : name.isEmpty;
    if (nameMissing || birthDate == null || city == null) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    final ReceivedCircleRequest? asked = request;
    if (flow == CircleFlow.approved && asked == null) {
      emit(state.copyWith(errorKey: 'error.invalid_data'));
      return false;
    }
    emit(
      state.copyWith(
        status: CreateStatus.saving,
        clearError: true,
        showErrors: false,
      ),
    );
    final Result<(CareCircleSummary, CircleAppMode), Failure> result =
        switch (flow) {
          CircleFlow.self => _detailed(
            await _circles.createSelfCircle(
              NewSelfCircle(name: name, birthDate: birthDate, city: city),
            ),
          ),
          CircleFlow.patient => _detailed(
            await _circles.createPatientCircle(
              NewPatientCircle(
                patientFirstName: state.patientFirstName.trim(),
                patientLastName: state.patientLastName.trim(),
                birthDate: birthDate,
                city: city,
              ),
            ),
          ),
          CircleFlow.approved => await _circles.completeRequest(
            asked!.id,
            CompleteCircleRequest(name: name, birthDate: birthDate, city: city),
          ),
        };
    if (isClosed) return false;
    return result.when(
      (data) {
        final (CareCircleSummary circle, CircleAppMode mode) = data;
        // Every open home screen loads the circles again and selects this one.
        _home.notifyCirclesChanged(select: circle.id);
        emit(
          state.copyWith(
            status: CreateStatus.created,
            switchToSimplified: mode == CircleAppMode.simplified,
          ),
        );
        return true;
      },
      (failure) {
        // The first try may have been saved with its answer lost. Loading the
        // circles again shows it.
        if (failure is AlreadyHasCircleFailure) _home.notifyCirclesChanged();
        emit(
          state.copyWith(
            status: CreateStatus.idle,
            errorKey: failure.messageKey,
            sessionEnded: _ended(failure),
          ),
        );
        return false;
      },
    );
  }

  /// A circle the person creates for themself or for a patient without the
  /// app leaves the account in the detailed mode (the server commits it).
  Result<(CareCircleSummary, CircleAppMode), Failure> _detailed(
    Result<CareCircleSummary, Failure> result,
  ) => result.when(
    (circle) => Success((circle, CircleAppMode.detailed)),
    (failure) => Error(failure),
  );

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
