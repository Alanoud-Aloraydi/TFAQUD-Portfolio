import 'dart:async';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_load_failed.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The simplified mode's home: a greeting, one card for what matters now
/// (the next task, a missed dose, or a finished day), the day's list, the
/// family to call, and the two squares (a reading, the emergency card).
class SimplifiedModeFeatureScreen extends StatefulWidget {
  const SimplifiedModeFeatureScreen({super.key});

  @override
  State<SimplifiedModeFeatureScreen> createState() =>
      _SimplifiedModeFeatureScreenState();
}

class _SimplifiedModeFeatureScreenState
    extends State<SimplifiedModeFeatureScreen>
    with WidgetsBindingObserver {
  final PhoneNotifications _phone = GetIt.I<PhoneNotifications>();
  StreamSubscription<String>? _taps;

  /// A reminder tapped before the day was read; opened once it is.
  ReminderRequest? _pendingReminder;

  /// Whether this phone's push token was asked for in this run.
  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final String? launchTap = _phone.takeLaunchTap();
    if (launchTap != null) {
      // Opened by «ذكّرني لاحقًا» in a notification: put it off again, and
      // open nothing.
      if (isSnoozeTap(launchTap)) {
        unawaited(
          context.read<SimplifiedModeCubit>().snoozeFromNotification(launchTap),
        );
      } else {
        _pendingReminder = reminderRequest(launchTap);
      }
    }
    _taps = _phone.taps.listen(_onTap);
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // A family member's picture may have changed on their phone while this
      // app was away; the day refresh below rebuilds it from a fresh read.
      GetIt.I<PrivatePhotoRepository>().invalidateCache();
      unawaited(context.read<SimplifiedModeCubit>().resumed());
    }
  }

  /// A reminder reads the day again (it may have changed since), then
  /// opens its full-screen reminder over whatever is on screen.
  Future<void> _onTap(String payload) async {
    if (!mounted) return;
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    if (isSnoozeTap(payload)) {
      await cubit.snoozeFromNotification(payload);
      return;
    }
    final ReminderRequest? request = reminderRequest(payload);
    if (request == null) return;
    await cubit.load();
    if (!mounted || cubit.state.day == null) return;
    unawaited(context.push(Routes.simplifiedReminder, extra: request));
  }

  /// Gives the server this phone's push token once the patient's day is
  /// read, as the detailed home does: a missed dose or measurement, and
  /// the circle's news, reach the patient in this mode too.
  void _startPush() {
    if (_pushStarted) return;
    _pushStarted = true;
    unawaited(GetIt.I<PushRegistration>().start());
  }

  void _openPending(BuildContext context) {
    final ReminderRequest? request = _pendingReminder;
    if (request == null) return;
    _pendingReminder = null;
    unawaited(context.push(Routes.simplifiedReminder, extra: request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimplifiedModeCubit, SimplifiedModeState>(
      listenWhen: (before, after) =>
          (after.day != null && before.day == null) ||
          (after.messageKey != null && after.messageKey != before.messageKey),
      listener: (context, state) {
        if (state.day != null) {
          _startPush();
          _openPending(context);
        }
        final String? key = state.messageKey;
        if (key != null && state.status == SimplifiedModeStatus.ready) {
          AppToast.show(context, key, kind: ToastKind.error);
          context.read<SimplifiedModeCubit>().messageShown();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: SimplifiedStyle.canvas,
          body: SafeArea(
            child: switch ((state.status, state.day, state.schedule)) {
              (_, final SimplifiedDay day, final TodaySchedule schedule) =>
                RefreshIndicator(
                  onRefresh: context.read<SimplifiedModeCubit>().load,
                  child: SimplifiedHomeBody(
                    day: day,
                    schedule: schedule,
                    now: state.now,
                    snoozes: state.snoozes,
                  ),
                ),
              (SimplifiedModeStatus.failure, _, _) => SimplifiedLoadFailed(
                messageKey: state.messageKey,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        );
      },
    );
  }
}
