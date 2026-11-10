import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'circles_di.config.dart';

@InjectableInit(
  initializerName: 'initCircles',
  generateForDir: ['lib/features/circles'],
)
void configureCircles(GetIt getIt) {
  getIt.initCircles();
}
