import 'package:app/core/utils/time_zones.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// The IANA zone this phone is set to: the first guess of the zone of a
/// city that is not one of the Saudi list (a new patient's, or the
/// account's own). Behind an interface, so tests give their own.
abstract interface class DeviceZone {
  /// The phone's zone (for example `Europe/London`); [defaultPatientZone]
  /// when the phone does not say.
  Future<String> current();
}

/// [DeviceZone] read from iOS or Android with flutter_timezone.
class PluginDeviceZone implements DeviceZone {
  @override
  Future<String> current() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on PlatformException {
      return defaultPatientZone;
    } on MissingPluginException {
      // The web and tests have no plugin.
      return defaultPatientZone;
    }
  }
}
