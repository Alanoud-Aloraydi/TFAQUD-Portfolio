import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_choice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «متى أذكّرك؟»: three big choices, each with the clock time it means.
/// It scrolls when the text is large, so no choice is cut off.
class SimplifiedSnoozeScreen extends StatelessWidget {
  const SimplifiedSnoozeScreen({super.key, required this.task});

  /// The dose or measurement the patient chose to put off; appointments
  /// are not put off.
  final TodayTask task;

  /// The three lengths offered here. Their words are not written out:
  /// they are counted the way the detailed mode's ruler counts them, so
  /// one dose reads «بعد 30 دقيقة» in both modes and never «بعد نصف ساعة»
  /// in one and a number in the other.
  static const List<Duration> _choices = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  /// How long this task may be put off. A dose is never pushed past
  /// halfway to the next dose of the same medicine, the same rule the
  /// detailed mode's ruler follows; anything else has the plain limit.
  static Duration _limit(
    BuildContext context,
    TodayTask task,
    SimplifiedDay? day,
    DateTime now,
  ) {
    final DoseOccurrence? dose = task.dose;
    if (dose == null || day == null) return maxSnooze;
    final PatientClock clock = PatientClockScope.of(context);
    return doseSnoozeLimit(dose, day.doses, clock, now);
  }

  Future<void> _choose(BuildContext context, Duration after) async {
    await context.read<SimplifiedModeCubit>().snooze(task: task, after: after);
    if (context.mounted) context.go(Routes.simplifiedMode);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = context.select<SimplifiedModeCubit, DateTime>(
      (cubit) => cubit.state.now,
    );
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (cubit) => cubit.state.saving,
    );
    final SimplifiedDay? day = context
        .select<SimplifiedModeCubit, SimplifiedDay?>(
          (cubit) => cubit.state.day,
        );
    final Duration limit = _limit(context, task, day, now);
    // «الساعة 11:26 م», the detailed sheet's own line under the length.
    String clock(Duration after) => context.tr(
      'reminders.snooze_at',
      args: <String>[simplifiedClockAt(context, now.add(after))],
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SimplifiedStyle.reminderGround,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: _content(context, clock, saving, limit),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    String Function(Duration) clock,
    bool saving,
    Duration limit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.when_remind'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(28, color: SimplifiedStyle.surface),
          ),
          const SizedBox(height: 44),
          for (final Duration after in _choices) ...<Widget>[
            SimplifiedSnoozeChoice(
              label: afterDuration(context, after.inMinutes),
              clock: clock(after),
              onTap: saving || after > limit
                  ? null
                  : () => _choose(context, after),
            ),
            const SizedBox(height: 12),
          ],
          // A choice turned off says nothing by itself: say why, and say
          // it as soon as one is out of reach, not only when all three
          // are — the detailed sheet names its limit every time.
          if (_choices.any((Duration after) => after > limit))
            Text(
              limit < _choices.first
                  ? context.tr('simplified_mode.snooze_too_close')
                  : context.tr(
                      'simplified_mode.snooze_limit',
                      args: <String>[durationText(context, limit.inMinutes)],
                    ),
              textAlign: TextAlign.center,
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                color: SimplifiedStyle.onDarkMuted,
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(Routes.simplifiedMode),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: const StadiumBorder(),
                // The app's outlined buttons are white; on this dark
                // ground the button is only its edge and its words.
                backgroundColor: SimplifiedStyle.clear,
                foregroundColor: SimplifiedStyle.surface,
                side: const BorderSide(
                  color: SimplifiedStyle.onDarkMuted,
                  width: 1.5,
                ),
              ),
              child: Text(
                context.tr('simplified_mode.back'),
                style: SimplifiedStyle.head(
                  SimplifiedStyle.body,
                  color: SimplifiedStyle.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
