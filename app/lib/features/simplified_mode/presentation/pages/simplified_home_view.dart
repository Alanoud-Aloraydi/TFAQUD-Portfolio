import 'dart:async';

import 'package:app/app/services/push_registration.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The home for [state]: the day, a note that it failed, or that it loads.
class SimplifiedHomeView extends StatelessWidget {
  const SimplifiedHomeView({super.key, required this.state});

  final SimplifiedModeState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimplifiedColors.canvas,
      body: SafeArea(
        child: switch ((state.status, state.day, state.schedule)) {
          (_, final SimplifiedDay day, final TodaySchedule schedule) =>
            LogoRefresh(
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
          _ => const LoadingNote(),
        },
      ),
    );
  }
}

class SimplifiedLoadFailed extends StatelessWidget {
  const SimplifiedLoadFailed({super.key, required this.messageKey});

  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SimplifiedStyle.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.tr(messageKey ?? 'error.unknown'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedColors.ink,
            ),
          ),
          const SizedBox(height: SimplifiedStyle.gap),
          SimplifiedButton(
            label: context.tr('simplified_mode.try_again'),
            onPressed: context.read<SimplifiedModeCubit>().load,
          ),
        ],
      ),
    );
  }
}

/// Gives the server this phone's push token once the patient's day is
/// read, as the detailed home does: a missed dose or measurement, and
/// the circle's news, reach the patient in this mode too.
class SimplifiedHomePush {
  /// Whether this phone's push token was asked for in this run.
  bool _started = false;

  /// Asks for the token for [accountId], the first time only.
  void start(String accountId) {
    if (_started) return;
    _started = true;
    unawaited(GetIt.I<PushRegistration>().start(accountId: accountId));
  }
}
