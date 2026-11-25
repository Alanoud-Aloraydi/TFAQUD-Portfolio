import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/require_extra.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_done_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_reminder_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_skip_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_snooze_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:go_router/go_router.dart';

/// The simplified mode's screens about one task: its reminder, snoozing or
/// skipping it, and the word after it is done. The task travels as the
/// navigation's `extra`; without it the phone goes back to the home.
List<RouteBase> simplifiedTaskRoutes() => <RouteBase>[
  GoRoute(
    path: Routes.simplifiedReminder,
    redirect: requireExtra<ReminderRequest>(Routes.simplifiedMode),
    pageBuilder: iosModalPage(
      (context, state) =>
          SimplifiedReminderScreen(request: state.extra! as ReminderRequest),
    ),
  ),
  GoRoute(
    path: Routes.simplifiedSnooze,
    redirect: requireExtra<TodayTask>(Routes.simplifiedMode),
    pageBuilder: iosPage(
      (context, state) =>
          SimplifiedSnoozeScreen(task: state.extra! as TodayTask),
    ),
  ),
  GoRoute(
    path: Routes.simplifiedSkip,
    redirect: requireExtra<TodayTask>(Routes.simplifiedMode),
    pageBuilder: iosPage(
      (context, state) => SimplifiedSkipScreen(task: state.extra! as TodayTask),
    ),
  ),
  GoRoute(
    path: Routes.simplifiedDone,
    redirect: requireExtra<SimplifiedDoneMessage>(Routes.simplifiedMode),
    pageBuilder: iosPage(
      (context, state) =>
          SimplifiedDoneScreen(message: state.extra! as SimplifiedDoneMessage),
    ),
  ),
];
