import 'package:app/core/utils/account_ids.dart';

/// Who goes to an appointment: the circle's patient, and the members
/// chosen to go with them ([companionIds], accounts).
///
/// They are the ones its reminder reaches, and the ones «حضرت» is for: a
/// member may manage the circle's appointments — add them, change their
/// time — without having been at this one, and only someone who was there
/// can say it happened. One rule, read by the reminder schedulers
/// (`ReminderCircle.remindsOfAppointment`) and by the button
/// (`TaskViewerScope.goesWith`). The ids are matched by [sameAccount].
bool goesToAppointment({
  required bool isPatient,
  required String? viewerId,
  required Iterable<String> companionIds,
}) => isPatient || companionIds.any((String id) => sameAccount(id, viewerId));
