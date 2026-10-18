import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'core/setup.dart';
import 'core/theme/app_theme.dart';
import 'core/di/configure_dependencies.dart';
import 'core/navigation/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  await setup();
  await configureDependencies();

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
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          themeMode: ThemeMode.light,
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

