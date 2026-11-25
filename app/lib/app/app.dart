import 'package:app/app/router/app_router.dart';
import 'package:app/app/widgets/app_scopes.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/loading/launch_curtain.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The app: its router, theme and Arabic locale.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}
