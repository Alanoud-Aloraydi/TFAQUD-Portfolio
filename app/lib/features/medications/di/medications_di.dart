import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'medications_di.config.dart';

@InjectableInit(
  initializerName: 'initMedications',
  generateForDir: ['lib/features/medications'],
)
void configureMedications(GetIt getIt) {
  getIt.initMedications();
}
