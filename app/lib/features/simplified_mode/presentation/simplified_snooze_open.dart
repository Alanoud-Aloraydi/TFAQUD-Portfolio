import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/feedback/remind_later_check.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// «ذكّرني لاحقًا» in this mode: opens «متى أذكّرك؟» for [task], in place
/// of the reminder when [replace]. While the notifications are off it
/// stays here and says so, as the detailed mode does ([mayRemindLater]).
Future<void> openSimplifiedSnooze(
  BuildContext context,
  TodayTask task, {
  bool replace = false,
}) async {
  if (!await mayRemindLater(context) || !context.mounted) return;
  if (replace) {
    context.pushReplacement(Routes.simplifiedSnooze, extra: task);
  } else {
    await context.push(Routes.simplifiedSnooze, extra: task);
  }
}
