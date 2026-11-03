import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sizer/sizer.dart';

import 'core/services/phone_notifications.dart';
import 'core/setup.dart';
import 'core/theme/app_theme.dart';
import 'core/di/configure_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/services/app_accessibility.dart';
import 'core/theme/materials/glass_preferences.dart';
import 'core/widgets/forms/keyboard_dismiss.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  await setup();
  await configureDependencies();
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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          routerConfig: AppRouter.router,
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: AppAccessibility.reduceTransparency,
            builder: (context, reduceTransparency, _) => GlassPreferences(
              reduceTransparency: reduceTransparency,
              child: KeyboardDismissOnTap(child: child!),
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
