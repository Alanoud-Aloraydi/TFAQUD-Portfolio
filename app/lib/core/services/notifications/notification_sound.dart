import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// The app's own notification sound, a soft two-note chime; the server's
/// pushes name the same file (`sender.py`). iOS finds it in `Library/Sounds`
/// once [installNotificationSound] copies it there (a Flutter asset is not
/// in the main bundle); until then iOS plays its default.
const String notificationSound = 'tafaqod_chime.wav';

/// Where the sound is in the app's assets.
const String notificationSoundAsset = 'assets/sounds/$notificationSound';

/// Copies [notificationSound] to `Library/Sounds`, where iOS finds it for
/// the reminders and the pushes. Done once; a failure leaves iOS's default
/// sound, which is still a sound.
Future<void> installNotificationSound() async {
  try {
    final Directory library = await getLibraryDirectory();
    final File file = File('${library.path}/Sounds/$notificationSound');
    final data = await rootBundle.load(notificationSoundAsset);
    if (file.existsSync() && file.lengthSync() == data.lengthInBytes) {
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  } on Exception catch (error) {
    debugPrint('The notification sound was not copied: $error');
  }
}
