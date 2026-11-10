import 'package:app/core/utils/patient_clock.dart';
import 'package:flutter/widgets.dart';

/// Gives the pages below it the [PatientClock] of the circle on screen, so
/// every «now», «today» and time they show is the patient's own. Placed
/// once, above the router (`main.dart`), fed by `ShownCircleClock`.
class PatientClockScope extends InheritedWidget {
  const PatientClockScope({
    super.key,
    required this.clock,
    required super.child,
  });

  final PatientClock clock;

  /// The clock of the circle on screen. With no scope above (a widget test
  /// of one section) it is [defaultPatientZone]'s.
  static PatientClock of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PatientClockScope>()?.clock ??
      PatientClock(defaultPatientZone);

  @override
  bool updateShouldNotify(PatientClockScope oldWidget) =>
      clock != oldWidget.clock;
}
