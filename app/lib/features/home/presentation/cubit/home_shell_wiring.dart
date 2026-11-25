import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/features/home/presentation/cubit/clinical_data_loader.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_shell_actions.dart';
import 'package:app/features/home/presentation/cubit/home_shell_lifecycle.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:app/features/home/presentation/cubit/notification_tap_handler.dart';
import 'package:app/features/home/presentation/cubit/reminder_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Builds the phone-side controllers of the shell and ties them together.
HomeStateReactor createHomeStateReactor(BuildContext context, int tab) {
  final ClinicalDataLoader clinical = ClinicalDataLoader(
    medications: context.read(),
    measurementPlans: context.read(),
    appointments: context.read(),
    measurementTasks: context.read(),
    measurementReadings: context.read(),
    occurrences: context.read(),
    prayers: context.read(),
  );
  final ReminderSync reminders = ReminderSync(
    GetIt.I<DoseReminders>(),
    GetIt.I<CalendarSync>(),
  );
  final NotificationTapHandler taps = NotificationTapHandler(
    GetIt.I<PhoneNotifications>(),
    GetIt.I<DoseReminders>(),
    isReady: () => context.read<HomeCubit>().state.status == HomeStatus.ready,
    openToday: (String? circleId) => openToday(context, circleId),
    openInbox: () => openInbox(context),
    onSnoozed: () => showSnoozed(context),
  );
  return HomeStateReactor(clinical, reminders, taps, tab);
}

/// Reads the home again when the app comes back to the front. It listens
/// from [initState] to [dispose].
mixin HomeResumeRefresh<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  HomeStateReactor get reactor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    refreshOnResume(context, reactor);
  }
}
