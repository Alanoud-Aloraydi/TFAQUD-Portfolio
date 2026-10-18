import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ThirdPartyConfig {
  //----------------------------------------------------------------------------
  @lazySingleton
  GetStorage get storage => GetStorage();
  //----------------------------------------------------------------------------
  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions();
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage =>
      FlutterSecureStorage(aOptions: _getAndroidOptions());
  //----------------------------------------------------------------------------
}

