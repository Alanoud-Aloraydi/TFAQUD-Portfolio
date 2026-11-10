import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'home_di.config.dart';

@InjectableInit(
  initializerName: 'initHome',
  generateForDir: ['lib/features/home'],
)
void configureHome(GetIt getIt) {
  getIt.initHome();
}
