import 'package:app/core/services/appointment_audience.dart';
import 'package:flutter/widgets.dart';

/// Who the person on this phone is in the circle on screen: their account,
/// and whether they are its patient. Placed by `SelectedCircleBuilder`
/// above each tab, so a task's buttons can tell whether the task is theirs
/// to answer — the way `PatientClockScope` gives them the patient's clock.
class TaskViewerScope extends InheritedWidget {
  const TaskViewerScope({
    super.key,
    required this.accountId,
    required this.isPatient,
    this.standsIn = false,
    required super.child,
  });

  /// The signed-in account.
  final String accountId;

  /// Whether that account is this circle's patient.
  final bool isPatient;

  /// Whether it leads the circle of a patient without a phone, and so
  /// answers «حضرت» for a visit nobody goes with.
  final bool standsIn;

  /// The viewer of the circle on screen; null with no scope above, as in a
  /// widget test of one section on its own.
  static TaskViewerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TaskViewerScope>();

  /// Whether this person goes to an appointment whose companions are
  /// [companionIds], and so may answer «حضرت» for it.
  bool goesWith(Iterable<String> companionIds) => goesToAppointment(
    isPatient: isPatient,
    viewerId: accountId,
    companionIds: companionIds,
    standsIn: standsIn,
  );

  @override
  bool updateShouldNotify(TaskViewerScope oldWidget) =>
      accountId != oldWidget.accountId ||
      isPatient != oldWidget.isPatient ||
      standsIn != oldWidget.standsIn;
}
