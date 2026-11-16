import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/utils/time_zones.dart';
import 'package:equatable/equatable.dart';
import 'package:timezone/timezone.dart' as tz;

/// The wall clock where a circle's patient lives.
///
/// Every day and time of a circle (doses, readings, visits, «اليوم») is
/// the patient's own, whoever records and wherever their phone is: a dose
/// at «08:00» is 08:00 where the patient lives. Two scales are used:
///
/// * a *wall time* is a `DateTime.utc` whose fields read the patient's
///   clock ([now], [wallTime], [wallClockAt]); compare wall times only
///   with wall times;
/// * a *moment* is a real UTC instant ([momentOf]), for what the phone
///   must do at the right time (a reminder, a calendar event).
///
/// Both follow the zone's real rules, DST included, never a fixed offset.
class PatientClock extends Equatable {
  /// The clock of the IANA [zone] (for example `Europe/London`). An unknown
  /// name (a zone newer than this app's database) uses
  /// [defaultPatientZone]. [clock] is the instant source, for tests.
  PatientClock(String zone, {DateTime Function()? clock})
    : location = _location(zone),
      _clock = clock ?? DateTime.now;

  /// The zone's rules.
  final tz.Location location;
  final DateTime Function() _clock;

  /// The IANA name of the zone.
  String get zone => location.name;

  /// The patient's wall time now.
  DateTime now() => wallTime(_clock());

  /// The patient's wall time at the instant [instant].
  DateTime wallTime(DateTime instant) {
    final tz.TZDateTime local = tz.TZDateTime.from(instant, location);
    return DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
    );
  }

  /// The patient's calendar day at [instant] (now when left out), as a
  /// date-only value ([scheduleDay]).
  DateTime today([DateTime? instant]) =>
      scheduleDay(wallTime(instant ?? _clock()));

  /// The real moment (UTC) of the patient's «HH:mm» [time] on [day]. A
  /// time skipped by a DST jump lands at the zone's next valid time.
  DateTime momentOf(DateTime day, String time) {
    final List<String> parts = time.split(':');
    return tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    ).toUtc();
  }

  static tz.Location _location(String zone) {
    ensureTimeZones();
    try {
      return tz.getLocation(zone);
    } on tz.LocationNotFoundException {
      return tz.getLocation(defaultPatientZone);
    }
  }

  @override
  List<Object?> get props => [zone];
}
