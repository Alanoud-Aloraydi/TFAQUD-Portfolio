import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/presentation/cubit/circle_flow.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_call.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_scope.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/cubit/create_status.dart';
import 'package:app/features/circles/presentation/cubit/name_preset.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Creating the circle, once the page has every answer.
mixin CreateCircleCreating on Cubit<CreateCircleState>, CreateCircleScope {
  /// Creates the circle of the [flow]. [presetName] is the text of the
  /// chosen chip, which the page translates; the [CircleFlow.patient] flow
  /// names nothing (the server names it «دائرة» and the patient's first
  /// name). A missing answer marks the fields and sends nothing. A tap while
  /// the account loads, while saving or after the circle was created sends
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
    final result = await createCircleCall(
      circles,
      flow: flow,
      state: state,
      name: name,
      birthDate: birthDate,
      city: city,
      request: asked,
    );
    if (isClosed) return false;
    return result.when(
      (data) {
        final (CareCircleSummary circle, CircleAppMode mode) = data;
        // Every open home screen loads the circles again and selects this one.
        home.notifyCirclesChanged(select: circle.id);
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
        if (failure is AlreadyHasCircleFailure) home.notifyCirclesChanged();
        emit(
          state.copyWith(
            status: CreateStatus.idle,
            errorKey: failure.messageKey,
            sessionEnded: endedSession(failure),
          ),
        );
        return false;
      },
    );
  }
}
