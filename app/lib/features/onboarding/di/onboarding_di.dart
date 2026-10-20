import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'onboarding_di.config.dart'; 

@InjectableInit(
  initializerName: 'initOnboarding',
   // Optional: specify the directory to scan for injectable annotations
  generateForDir: ['lib/features/onboarding'],
)
void configureOnboarding(GetIt getIt) {
  getIt.initOnboarding();
}
