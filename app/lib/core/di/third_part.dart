import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:injectable/injectable.dart';

/// The third-party stores the container hands out.
@module
abstract class ThirdPartyConfig {
  @lazySingleton
  GetStorage get storage => GetStorage();

  /// The keychain on iOS; the tokens live here, not in [storage].
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage =>
      FlutterSecureStorage(aOptions: _androidOptions());

  AndroidOptions _androidOptions() => const AndroidOptions();
}
