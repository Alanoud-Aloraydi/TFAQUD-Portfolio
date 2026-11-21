import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_outline_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_skip_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «لماذا لم تأخذها؟»: the patient says a dose was not taken, and why, on
/// one calm dark colour like the reminder it follows. «سبب آخر» lets the
/// patient write the reason, as the detailed mode's note does, and it may
/// stay empty; «رجوع» writes nothing.
class SimplifiedSkipScreen extends StatelessWidget {
  const SimplifiedSkipScreen({super.key, required this.task});

  /// The dose the patient did not take.
  final TodayTask task;

  Future<void> _skip(
    BuildContext context,
    DoseSkipReason reason,
    String? note,
  ) async {
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    final DoseOccurrence dose = task.dose!;
    final bool saved = await cubit.skipDose(dose, reason, note: note);
    if (!saved || !context.mounted) return;
    context.pushReplacement(
      Routes.simplifiedDone,
      extra: SimplifiedDoneMessage.doseSkipped(dose.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (SimplifiedModeCubit cubit) => cubit.state.saving,
    );
    return SimplifiedDarkPage(
      actions: SimplifiedDarkOutlineButton(
        label: context.tr('simplified_mode.back'),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(Routes.simplifiedMode),
      ),
      child: SimplifiedSkipBody(
        name: task.dose!.name,
        saving: saving,
        onReason: (DoseSkipReason reason, String? note) =>
            unawaited(_skip(context, reason, note)),
      ),
    );
  }
}
