import 'package:equatable/equatable.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The zone of every patient made before zones were stored, of a city in
/// the app's Saudi list, and the one used when a zone is unknown. The only
/// fixed zone in the app; the server has the same default.
const String defaultPatientZone = 'Asia/Riyadh';

/// Loads the whole IANA zone database (with its DST rules and the old
/// alias names some phones report) once. Called at
/// startup; [PatientClock] calls it too, so a test needs no setup.
void ensureTimeZones() {
  if (!tz.timeZoneDatabase.isInitialized) tz_data.initializeTimeZones();
}

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

/// The newest calendar day anywhere on Earth (UTC+14) at [instant] (now
/// when left out): the bound of a date with no patient yet, such as the
/// account's own birth date at onboarding. The server uses the same bound.
DateTime latestToday([DateTime? instant]) => scheduleDay(
  (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 14)),
);

/// Preserves a date-only schedule value without changing its calendar day.
DateTime scheduleDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// The schedule day [days] calendar days after [day] (before it when
/// negative), as a date-only value. Calendar arithmetic, never steps of 24
/// hours: on a phone whose own zone changes its clocks, 24 hours from
/// midnight can stay on the same day.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// The wall time of «HH:mm» [time] on the schedule [date], on the scale of
/// [PatientClock.now]. Needs no zone: it only reads the patient's clock.
DateTime wallClockAt(DateTime date, String time) {
  final parts = time.split(':');
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

/// A scheduled occurrence (dose, measurement) can be recorded starting one
/// hour before its scheduled time, never earlier — the same rule across
/// every domain shown on «اليوم». Both values are wall times.
bool isRecordableNow(DateTime scheduledAt, DateTime now) =>
    !now.isBefore(scheduledAt.subtract(const Duration(hours: 1)));

/// One rule, shared by every domain on «اليوم»: a row offers its record
/// controls only while it is not already resolved, and not more than an
/// hour before its scheduled time.
bool canRecordOccurrence({
  required bool resolved,
  required DateTime scheduledAt,
  required DateTime now,
}) => !resolved && isRecordableNow(scheduledAt, now);
