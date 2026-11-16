import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';

/// The same page with one answer changed; [clearError] drops the message of
/// the try before it.
extension CreateCircleCopy on CreateCircleState {
  CreateCircleState copyWith({
    AccountSummary? account,
    AccountLoad? accountLoad,
    NamePreset? namePreset,
    String? customName,
    String? patientFirstName,
    String? patientLastName,
    DateTime? birthDate,
    String? city,
    bool? showErrors,
    CreateStatus? status,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
    bool? switchToSimplified,
  }) {
    return CreateCircleState(
      account: account ?? this.account,
      accountLoad: accountLoad ?? this.accountLoad,
      namePreset: namePreset ?? this.namePreset,
      customName: customName ?? this.customName,
      patientFirstName: patientFirstName ?? this.patientFirstName,
      patientLastName: patientLastName ?? this.patientLastName,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
      switchToSimplified: switchToSimplified ?? this.switchToSimplified,
    );
  }
}
