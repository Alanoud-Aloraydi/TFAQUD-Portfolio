import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/presentation/cubit/reminder_taps.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_home_view.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_skip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The simplified mode's home: a greeting, one card for what matters now
/// (the next task, a missed dose, or a finished day), the day's list, the
/// family to call, and the two squares (a reading, the emergency card).
class SimplifiedModeFeatureScreen extends StatefulWidget {
  const SimplifiedModeFeatureScreen({super.key});

  @override
  State<SimplifiedModeFeatureScreen> createState() => _SimplifiedModeState();
}

class _SimplifiedModeState extends State<SimplifiedModeFeatureScreen>
    with WidgetsBindingObserver {
  late final ReminderTaps _taps;
  final SimplifiedHomePush _push = SimplifiedHomePush();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taps = simplifiedHomeTaps(context);
    // The day may already be read by the time this screen is built, which
    // fires no change for the listener below to act on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _taps.openPending();
    });
  }

  @override
  void dispose() {
    _taps.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimplifiedModeCubit, SimplifiedModeState>(
      listenWhen: simplifiedHomeListens,
      listener: (context, state) =>
          simplifiedHomeListen(context, state, push: _push, taps: _taps),
      builder: (context, state) => SimplifiedHomeView(state: state),
    );
  }
}

/// The reminder taps of the home opened from [context]: they open the
/// full-screen reminder once the day is read.
ReminderTaps simplifiedHomeTaps(BuildContext context) {
  return ReminderTaps(
    phone: GetIt.I<PhoneNotifications>(),
    hasDay: () => context.read<SimplifiedModeCubit>().state.day != null,
    snooze: (String tap) =>
        context.read<SimplifiedModeCubit>().snoozeFromNotification(tap),
    open: (ReminderRequest request) =>
        unawaited(context.push(Routes.simplifiedReminder, extra: request)),
  );
}
