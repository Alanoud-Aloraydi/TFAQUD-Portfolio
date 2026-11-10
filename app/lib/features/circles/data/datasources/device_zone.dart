import 'package:app/core/utils/patient_clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';

/// The IANA zone this phone is set to: the first guess of a new patient's
/// zone when their city is not one of the Saudi list. Behind an interface,
/// so tests give their own.
abstract interface class DeviceZone {
  /// The phone's zone (for example `Europe/London`); [defaultPatientZone]
  /// when the phone does not say.
  Future<String> current();
}

/// [DeviceZone] read from iOS or Android with flutter_timezone.
@LazySingleton(as: DeviceZone)
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
