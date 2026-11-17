import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sizer/sizer.dart';

import 'core/di/configure_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/network/api_options.dart';
import 'core/services/fresh_install.dart';
import 'core/services/phone_notifications.dart';
import 'core/services/reminders/dose_reminders.dart';
import 'core/services/reminders/reminders_enabled.dart';
import 'core/services/remote_push.dart';
import 'core/services/token_storage.dart';
import 'core/setup.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_scopes.dart';
import 'core/widgets/loading/launch_curtain.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  await setup();
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

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('ar')],
      path: 'assets/translations',
      startLocale: Locale('ar'),
      fallbackLocale: Locale('ar'),
      child: MainApp(),
    ),
  );
}

/// Displays the main app UI.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          routerConfig: AppRouter.router,
          // The launch logo fades away over the app once it is ready.
          builder: (context, child) =>
              AppScopes(child: LaunchCurtain(child: child!)),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          themeMode: ThemeMode.light,
          theme: AppTheme.lightTheme,
          // iOS Increase Contrast: secondary text and status words turn ink.
          highContrastTheme: AppTheme.highContrastTheme,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
