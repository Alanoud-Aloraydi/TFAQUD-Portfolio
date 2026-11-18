import 'package:app/core/di/app_services_di.dart';
import 'package:app/core/di/care_di.dart';
import 'package:app/core/di/configure_dependencies.config.dart';
import 'package:app/core/di/push_di.dart';
import 'package:app/core/di/reminders_di.dart';
import 'package:app/features/account/di/account_di.dart';
import 'package:app/features/auth/di/auth_di.dart';
import 'package:app/features/circles/di/circles_di.dart';
import 'package:app/features/home/di/home_di.dart';
import 'package:app/features/medications/di/medications_di.dart';
import 'package:app/features/simplified_mode/di/simplified_mode_di.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  generateForDir: ['lib/core'],
)
Future<void> configureDependencies() async {
  final getIt = GetIt.instance;
  getIt.init();
  configureAuth(getIt);
  configureAccount(getIt);
  configureHome(getIt);
  configureCircles(getIt);
  configureMedications(getIt);
  configureAppServices(getIt);
  configureCare(getIt);
  configureReminders(getIt);
  // The server's pushes (OneSignal, and the Apple token for now).
  configurePush(getIt);
  configureSimplifiedMode(getIt);
}
