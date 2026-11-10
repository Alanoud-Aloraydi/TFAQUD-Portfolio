import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'account_di.config.dart';

/// Registers the account feature's profile data source, repository and use
/// case in [GetIt]. Called once at start-up by `configureDependencies`.
@InjectableInit(
  initializerName: 'initAccount',
  generateForDir: ['lib/features/account'],
)
void configureAccount(GetIt getIt) {
  getIt.initAccount();
}
