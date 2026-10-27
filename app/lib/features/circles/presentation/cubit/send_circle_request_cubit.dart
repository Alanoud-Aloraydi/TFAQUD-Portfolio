import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sends the request to a patient who uses the app. The circle does not exist
/// after this: the patient has to agree and complete the details first.
class SendCircleRequestCubit extends Cubit<SendCircleRequestState> {
  SendCircleRequestCubit(this._circles)
    : super(const SendCircleRequestState());

  final CirclesUseCase _circles;

  /// A Saudi mobile number without the country code or a leading zero: nine
  /// digits that start with 5. The same rule as the sign-in page.
  static final RegExp _phonePattern = RegExp(r'^5[0-9]{8}$');

  static const String countryCode = '+966';

  bool get isPhoneValid => _phonePattern.hasMatch(state.phone);

  /// [digits] are the digits the user typed, already written 0-9.
  void phoneChanged(String digits) {
    emit(state.copyWith(phone: digits, clearError: true));
  }

  void chooseLabel(CircleLabel label) {
    emit(state.copyWith(label: label, clearError: true));
  }

  void customLabelChanged(String value) {
    emit(state.copyWith(customLabel: value, clearError: true));
  }

  void chooseMode(CircleAppMode mode) {
    emit(state.copyWith(mode: mode, clearError: true));
  }

  /// Sends the request. [labelName] is the text of the chosen chip, which the
  /// page translates. Returns true when the server saved the request.
  Future<bool> send({required String labelName}) async {
    if (state.status == SendStatus.sending) return false;
    final String label = state.label == CircleLabel.other
        ? state.customLabel.trim()
        : labelName;
    if (!isPhoneValid || label.isEmpty) {
      emit(state.copyWith(showErrors: true, clearError: true));
      return false;
    }
    emit(
      state.copyWith(
        status: SendStatus.sending,
        showErrors: false,
        clearError: true,
      ),
    );
    final result = await _circles.sendCircleRequest(
      NewCircleRequest(
        patientPhoneNumber: '$countryCode${state.phone}',
        circleLabel: label,
        proposedAppMode: state.mode,
      ),
    );
    if (isClosed) return false;
    return result.when(
      (SentCircleRequest sent) {
        emit(state.copyWith(status: SendStatus.sent, sent: sent));
        return true;
      },
      (Failure failure) {
        emit(
          state.copyWith(
            status: SendStatus.idle,
            errorKey: failure.messageKey,
            sessionEnded: _ended(failure),
          ),
        );
        return false;
      },
    );
  }

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
