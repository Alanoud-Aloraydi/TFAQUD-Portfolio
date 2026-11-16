import 'package:app/core/utils/patient_clock.dart';
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
