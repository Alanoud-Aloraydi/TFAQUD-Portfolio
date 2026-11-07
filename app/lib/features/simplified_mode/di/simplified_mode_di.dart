import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'simplified_mode_di.config.dart';

@InjectableInit(
  initializerName: 'initSimplifiedMode',
  generateForDir: ['lib/features/simplified_mode'],
)
void configureSimplifiedMode(GetIt getIt) {
  getIt.initSimplifiedMode();
}
