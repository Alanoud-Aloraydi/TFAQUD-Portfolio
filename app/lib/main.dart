import 'package:app/app/app.dart';
import 'package:app/app/bootstrap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'assets/translations',
      startLocale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      child: const MainApp(),
    ),
  );
}
