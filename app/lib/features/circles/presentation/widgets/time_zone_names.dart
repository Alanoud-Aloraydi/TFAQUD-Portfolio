import 'package:app/core/utils/time_zones.dart';
import 'package:timezone/timezone.dart' as tz;

/// The zone as a row shows it: its IANA name with spaces, «Europe / London».
/// The names stay as the IANA database writes them: there is no Arabic
/// name for each of the world's zones.
String timeZoneName(String zone) =>
    zone.replaceAll('_', ' ').replaceAll('/', ' / ');

/// Every place zone of the database, by name («Etc/GMT+3» style offsets
/// are left out: they have no DST and no place).
List<String> placeTimeZones() {
  ensureTimeZones();
  return tz.timeZoneDatabase.locations.keys
      .where((String name) => name.contains('/') && !name.startsWith('Etc/'))
      .toList()
    ..sort();
}
