import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sizer/sizer.dart';

import 'core/di/configure_dependencies.dart';
import 'core/media/private_photo_repository.dart';
import 'core/navigation/app_router.dart';
import 'core/network/api_options.dart';
import 'core/services/app_accessibility.dart';
import 'core/services/fresh_install.dart';
import 'core/services/phone_notifications.dart';
import 'core/services/shown_circle_clock.dart';
import 'core/services/token_storage.dart';
import 'core/setup.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/components/navigation_themes.dart';
import 'core/theme/materials/glass_preferences.dart';
import 'core/widgets/forms/keyboard_dismiss.dart';
import 'core/widgets/patient_clock_scope.dart';

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
          // Dark status bar icons on every page, also the ones without an
          // app bar (the tabs draw their own glass top bar).
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppNavigationThemes.systemBars,
            child: RepositoryProvider<PrivatePhotoRepository>.value(
              value: GetIt.I<PrivatePhotoRepository>(),
              child: ValueListenableBuilder<bool>(
                valueListenable: AppAccessibility.reduceTransparency,
                builder: (context, reduceTransparency, _) => GlassPreferences(
                  reduceTransparency: reduceTransparency,
                  // Above the router, so a page opened on the root
                  // navigator reads the same patient's clock.
                  child: ValueListenableBuilder(
                    valueListenable: GetIt.I<ShownCircleClock>(),
                    builder: (context, clock, _) => PatientClockScope(
                      clock: clock,
                      child: KeyboardDismissOnTap(child: child!),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
