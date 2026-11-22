import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/one_signal_remote_push.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:get_it/get_it.dart';
import 'package:app/core/network/account_endpoints.dart';

/// The server's pushes through OneSignal on iOS and Android: [RemotePush]
/// (the only way into its SDK), and [PushRegistration], which ties the
/// signed-in account to this phone and gives the server the phone's
/// subscription, so a deleted app ends its sign-in. With it the app asks
/// for the server's reminders at the tasks' times; the answer says whether
/// this phone still sets its own ([ServerReminders]).
void configurePush(GetIt getIt) {
  getIt.registerLazySingleton<RemotePush>(OneSignalRemotePush.new);
  getIt.registerLazySingleton<PushRegistration>(
    () => PushRegistration(
      getIt<PhoneNotifications>(),
      remote: getIt<RemotePush>(),
      send: (String subscriptionId) async {
        final answer = await getIt<DioClient>().put(
          AccountEndpoints.pushSubscription,
          data: <String, Object>{
            'subscription_id': subscriptionId,
            // Only while OneSignal shows this phone the pushes: else the
            // phone keeps its own reminders.
            'server_reminders': getIt<RemotePush>().receivesPushes,
          },
        );
        await getIt<DoseReminders>().server.set(serverRemindsFrom(answer.data));
      },
    ),
  );
}
