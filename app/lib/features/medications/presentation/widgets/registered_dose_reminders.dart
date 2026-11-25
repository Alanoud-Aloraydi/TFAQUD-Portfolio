import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:get_it/get_it.dart';

/// The reminders, where the app has them (a test of a card may not).
DoseReminders? registeredDoseReminders() =>
    GetIt.I.isRegistered<DoseReminders>() ? GetIt.I<DoseReminders>() : null;
