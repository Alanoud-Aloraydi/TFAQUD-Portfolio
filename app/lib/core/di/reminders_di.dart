import 'package:app/core/l10n/dose_reminder_texts.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:app/core/network/circle_endpoints.dart';

/// What the phone itself shows: its notifications, the reminders that use
/// them, and the optional mirror onto its Calendar app.
void configureReminders(GetIt getIt) {
  // The notifications set on the phone, and the reminders that use them:
  // doses, measurements and appointments.
  getIt.registerLazySingleton<PhoneNotifications>(
    () => PluginPhoneNotifications(pushTaps: getIt<RemotePush>().taps),
  );
  getIt.registerLazySingleton<DoseReminders>(
    () => DoseReminders(
      getIt<MedicationsUseCase>(),
      getIt<PhoneNotifications>(),
      texts: doseReminderTexts,
      measurements: getIt<MeasurementsUseCase>(),
      appointments: getIt<AppointmentsUseCase>(),
      // «ذكّرني لاحقًا» goes to the whole circle.
      share: (SnoozeShare snooze) => getIt<DioClient>().put(
        CircleEndpoints.taskSnoozes(snooze.circleId),
        data: snooze.toJson(),
      ),
    ),
  );
  // Optional mirror of doses, measurements and appointments onto the
  // phone's own Calendar app, with the tasks put off at their new times;
  // off until the person turns it on.
  getIt.registerLazySingleton<CalendarSync>(
    () => CalendarSync(
      getIt<MedicationsUseCase>(),
      getIt<MeasurementsUseCase>(),
      getIt<AppointmentsUseCase>(),
      snoozes: getIt<DoseReminders>().snoozes,
    ),
  );
}
