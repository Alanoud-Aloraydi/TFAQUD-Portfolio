import 'package:app/core/services/app_accessibility.dart';
import 'package:app/core/services/fresh_install.dart';
import 'package:app/core/services/native_glass.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

Future<void> setup() async {
  //----------------------------------------------------------------------------
  await dotenv.load(fileName: ".env");
  //----------------------------------------------------------------------------
  // Before GetStorage.init, which makes the file this looks for.
  await FreshInstall.check();
  await GetStorage.init();
  //----------------------------------------------------------------------------
  // iOS 26 or later draws the add button as Apple's own glass.
  await NativeGlass.detect();
  await AppAccessibility.initialize();
  // The IANA zones, for each circle's own clock and the reminders' moments.
  ensureTimeZones();
  //----------------------------------------------------------------------------
}
