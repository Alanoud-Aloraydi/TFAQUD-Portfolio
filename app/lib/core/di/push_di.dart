import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/one_signal_remote_push.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:get_it/get_it.dart';
import 'package:app/core/network/account_endpoints.dart';

/// The server's pushes through OneSignal on iOS and Android: [RemotePush]
/// (the only way into its SDK), and [PushRegistration], which ties the
/// signed-in account to this phone and gives the server the phone's
/// subscription, so a deleted app ends its sign-in.
void configurePush(GetIt getIt) {
  getIt.registerLazySingleton<RemotePush>(OneSignalRemotePush.new);
  getIt.registerLazySingleton<PushRegistration>(
    () => PushRegistration(
      getIt<PhoneNotifications>(),
      remote: getIt<RemotePush>(),
      send: (String subscriptionId) => getIt<DioClient>().put(
        AccountEndpoints.pushSubscription,
        data: <String, String>{'subscription_id': subscriptionId},
      ),
    ),
  );
}
