import 'package:app/core/services/native_glass.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

Future<void> setup() async {
  //----------------------------------------------------------------------------
  await dotenv.load(fileName: ".env");
  //----------------------------------------------------------------------------
  await GetStorage.init();
  //----------------------------------------------------------------------------
  // iOS 26 or later draws the add button as Apple's own glass.
  await NativeGlass.detect();
  //----------------------------------------------------------------------------
}

