import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';

/// What makes two [SimplifiedDay]s equal: every field, in the order the
/// class declares them.
List<Object?> simplifiedDayProps(SimplifiedDay day) => <Object?>[
  day.circleId,
  day.circleName,
  day.accountId,
  day.isPatient,
  day.displayName,
  day.avatarCode,
  day.timeZone,
  day.doses,
  day.measurements,
  day.appointments,
  day.family,
  day.reasons,
  day.prayers,
  day.latitude,
  day.longitude,
];
