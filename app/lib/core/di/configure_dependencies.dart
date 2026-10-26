import 'package:get_it/get_it.dart';
import 'package:app/core/di/configure_dependencies.config.dart';
import 'package:injectable/injectable.dart';
import 'package:app/features/auth/di/auth_di.dart';
import 'package:app/features/onboarding/di/onboarding_di.dart';
import 'package:app/features/home/di/home_di.dart';
import 'package:app/features/circles/di/circles_di.dart';

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
  configureOnboarding(getIt);
  configureHome(getIt);
  configureCircles(getIt);
}
