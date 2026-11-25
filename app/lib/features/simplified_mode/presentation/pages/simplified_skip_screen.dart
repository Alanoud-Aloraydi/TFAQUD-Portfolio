import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/reminder_taps.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_home_view.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_choice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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

/// Every state with a day, not only the first: a reminder tapped while
/// the day was still being read waits for one of them.
bool simplifiedHomeListens(
  SimplifiedModeState before,
  SimplifiedModeState after,
) {
  return after.day != null ||
      (after.messageKey != null && after.messageKey != before.messageKey);
}

/// Starts the push and the pending reminder once the day is read, and
/// shows a failure once.
void simplifiedHomeListen(
  BuildContext context,
  SimplifiedModeState state, {
  required SimplifiedHomePush push,
  required ReminderTaps taps,
}) {
  if (state.day case final SimplifiedDay day) {
    push.start(day.accountId);
    taps.openPending();
  }
  final String? key = state.messageKey;
  if (key != null && state.status == SimplifiedModeStatus.ready) {
    AppToast.show(context, key, kind: ToastKind.error);
    context.read<SimplifiedModeCubit>().messageShown();
  }
}

/// «لماذا لم تأخذها؟» over the medicine's name, then the reasons; «سبب
/// آخر» opens a field to write it. The reason is never required, so no
/// answer blocks the record.
class SimplifiedSkipBody extends StatefulWidget {
  const SimplifiedSkipBody({
    super.key,
    required this.name,
    required this.saving,
    required this.onReason,
  });

  /// The medicine that was not taken.
  final String name;
  final bool saving;

  /// The reason, and with «سبب آخر» what the patient wrote (null if empty).
  final void Function(DoseSkipReason reason, String? note) onReason;

  @override
  State<SimplifiedSkipBody> createState() => _SimplifiedSkipBodyState();
}

class _SimplifiedSkipBodyState extends State<SimplifiedSkipBody> {
  final TextEditingController _note = TextEditingController();
  bool _writing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final String note = _note.text.trim();
    widget.onReason(DoseSkipReason.other, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      simplifiedSkipQuestion(context, widget.name),
      const SizedBox(height: 28),
      if (_writing)
        ...simplifiedSkipOther(
          context,
          note: _note,
          onSave: widget.saving ? null : _save,
        )
      else
        ...simplifiedSkipReasons(
          context,
          saving: widget.saving,
          onReason: (DoseSkipReason reason) => widget.onReason(reason, null),
          onOther: () => setState(() => _writing = true),
        ),
    ],
  );
}

/// «لماذا لم تأخذها؟» over the medicine's [name], read as one sentence.
Widget simplifiedSkipQuestion(BuildContext context, String name) =>
    MergeSemantics(
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.skip_question'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(
              SimplifiedStyle.display,
              color: SimplifiedColors.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.title,
              color: SimplifiedColors.onDarkMuted,
            ),
          ),
        ],
      ),
    );

/// «سبب آخر»: the patient writes the reason (250 characters at most, and
/// it may stay empty), then «سجّل» records the dose as not taken.
List<Widget> simplifiedSkipOther(
  BuildContext context, {
  required TextEditingController note,
  required VoidCallback? onSave,
}) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: SimplifiedColors.ink, width: 2),
  );
  return <Widget>[
    TextField(
      controller: note,
      autofocus: true,
      minLines: 2,
      maxLines: 4,
      maxLength: 250,
      inputFormatters: const [CodePointLengthFormatter(250)],
      style: SimplifiedStyle.text(
        SimplifiedStyle.body,
        color: SimplifiedColors.ink,
        weight: AppTextTheme.medium,
      ),
      decoration: InputDecoration(
        hintText: context.tr('simplified_mode.skip_other_hint'),
        filled: true,
        fillColor: SimplifiedColors.surface,
        contentPadding: const EdgeInsets.all(18),
        border: border,
        enabledBorder: border,
      ),
    ),
    const SizedBox(height: 12),
    SimplifiedDarkChoice(
      label: context.tr('simplified_mode.skip_save'),
      onTap: onSave,
    ),
  ];
}

const Map<String, DoseSkipReason> _reasons = <String, DoseSkipReason>{
  'simplified_mode.skip_forgotten': DoseSkipReason.forgotten,
  'simplified_mode.skip_unavailable': DoseSkipReason.unavailable,
  'simplified_mode.skip_side_effects': DoseSkipReason.sideEffects,
};

/// Three reasons in the patient's own words, then «سبب آخر» ([onOther]).
/// All of them wait while an answer is being saved.
List<Widget> simplifiedSkipReasons(
  BuildContext context, {
  required bool saving,
  required void Function(DoseSkipReason reason) onReason,
  required VoidCallback onOther,
}) {
  Widget choice(String key, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SimplifiedDarkChoice(
      label: context.tr(key),
      onTap: saving ? null : onTap,
    ),
  );
  return <Widget>[
    for (final MapEntry<String, DoseSkipReason> reason in _reasons.entries)
      choice(reason.key, () => onReason(reason.value)),
    choice('simplified_mode.skip_other', onOther),
  ];
}
