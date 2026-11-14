import 'package:app/core/services/one_signal_remote_push.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:get_it/get_it.dart';

/// The server's pushes through OneSignal on iOS and Android: [RemotePush]
/// (the only way into its SDK), and [PushRegistration], which ties the
/// signed-in account to this phone.
void configurePush(GetIt getIt) {
  getIt.registerLazySingleton<RemotePush>(OneSignalRemotePush.new);
  getIt.registerLazySingleton<PushRegistration>(
    () => PushRegistration(
      getIt<PhoneNotifications>(),
      remote: getIt<RemotePush>(),
    ),
  );
}
