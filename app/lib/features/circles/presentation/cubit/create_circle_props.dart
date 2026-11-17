import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';

/// What makes two [CreateCircleState]s equal: every field, in the order the
/// class declares them.
List<Object?> createCircleProps(CreateCircleState state) => <Object?>[
  state.account,
  state.accountLoad,
  state.namePreset,
  state.customName,
  state.patientFirstName,
  state.patientLastName,
  state.birthDate,
  state.city,
  state.showErrors,
  state.status,
  state.errorKey,
  state.sessionEnded,
  state.switchToSimplified,
];
