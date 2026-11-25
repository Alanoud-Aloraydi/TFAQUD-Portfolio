import 'dart:async';

import 'package:app/app/di/injection.dart';
import 'package:app/app/services/app_accessibility.dart';
import 'package:app/app/services/fresh_install.dart';
import 'package:app/app/services/native_glass.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/app/services/reminders/reminders_enabled.dart';
import 'package:app/app/services/remote_push.dart';
import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/core/utils/time_zones.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

/// Everything that must be ready before the first frame, in order.
Future<void> bootstrap() async {
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Before GetStorage.init, which makes the file this looks for.
  await FreshInstall.check();
  await GetStorage.init();
  // iOS 26 or later draws the add button as Apple's own glass.
  await NativeGlass.detect();
  await AppAccessibility.initialize();
  // هجري or ميلادي, as chosen on this phone, before any date is written.
  await AppCalendar.restore();
  // The IANA zones, for each circle's own clock and the reminders' moments.
  ensureTimeZones();
  await configureDependencies();
  // Installed again: the sign-in the Keychain kept from before is ended, so
  // the app opens signed out.
  if (FreshInstall.firstStart) {
    await LeftoverSignIn(GetIt.I<TokenStorage>(), Dio(buildApiOptions())).end();
  }
  // Early, so the tap on a reminder that opened the app is not lost.
  await GetIt.I<PhoneNotifications>().initialize();
  // The server's pushes (OneSignal), after the phone's own reminders so
  // both keep answering the phone's notification taps on iOS.
  await GetIt.I<RemotePush>().initialize();
  // The app's notifications switch covers the server's pushes too.
  final RemindersEnabled reminders = GetIt.I<DoseReminders>().enabled;
  reminders.on.addListener(
    () => unawaited(GetIt.I<RemotePush>().setWanted(reminders.on.value)),
  );
}
