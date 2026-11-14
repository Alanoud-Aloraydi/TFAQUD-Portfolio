import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/one_signal_remote_push.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:get_it/get_it.dart';

/// The server's pushes: OneSignal on iOS and Android ([RemotePush], the
/// only way into its SDK), and the Apple token the server sends to
/// directly until it sends through OneSignal ([PushRegistration]).
void configurePush(GetIt getIt) {
  getIt.registerLazySingleton<RemotePush>(OneSignalRemotePush.new);
  getIt.registerLazySingleton<PushRegistration>(
    () => PushRegistration(
      getIt<PhoneNotifications>(),
      (String token) => getIt<DioClient>().put(
        ApiEndpoints.pushDevice,
        data: <String, String>{'token': token},
      ),
      remote: getIt<RemotePush>(),
    ),
  );
}
