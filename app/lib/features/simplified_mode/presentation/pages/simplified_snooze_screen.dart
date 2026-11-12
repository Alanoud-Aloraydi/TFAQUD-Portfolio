import 'package:app/core/navigation/routers.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_speech.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The [SpokenPart.id]s of the question and of «رجوع»; each choice's is
/// its translation key.
const Object _questionPart = #question;
const Object _backPart = #back;
const Object _nonePart = #none;

/// «متى أذكّرك؟»: three big choices, each with the clock time it means.
/// A dose shows only the choices that keep it within 12 hours and before
/// halfway to the next dose of the same medicine; with none left, a line
/// says so. It scrolls when the text is large, so no choice is cut off.
class SimplifiedSnoozeScreen extends StatelessWidget {
  const SimplifiedSnoozeScreen({super.key, required this.task});

  /// The dose or measurement the patient chose to put off; appointments
  /// are not put off.
  final TodayTask task;

  static const List<(String, Duration)> _choices = <(String, Duration)>[
    ('simplified_mode.after_15', Duration(minutes: 15)),
    ('simplified_mode.after_30', Duration(minutes: 30)),
    ('simplified_mode.after_60', Duration(hours: 1)),
  ];

  /// The choices that fit: for a dose, no later than [doseSnoozeLimit]
  /// allows from [now].
  List<(String, Duration)> _fitting(BuildContext context, DateTime now) {
    final DoseOccurrence? dose = task.dose;
    final SimplifiedDay? day = context.read<SimplifiedModeCubit>().state.day;
    if (dose == null || day == null) return _choices;
    final Duration limit = doseSnoozeLimit(dose, day.doses, day.clock, now);
    return <(String, Duration)>[
      for (final (String, Duration) choice in _choices)
        if (choice.$2 <= limit) choice,
    ];
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
    String clock(Duration after) => simplifiedClockAt(context, now.add(after));
    final List<(String, Duration)> choices = _fitting(context, now);

    return ListenScope(
      parts: <SpokenPart>[
        (id: _questionPart, text: context.tr('simplified_mode.when_remind')),
        if (choices.isEmpty)
          (id: _nonePart, text: context.tr('reminders.snooze_none')),
        for (final (String key, Duration after) in choices)
          (id: key, text: sentences(<String>[context.tr(key), clock(after)])),
        (id: _backPart, text: context.tr('simplified_mode.back')),
      ],
      child: Scaffold(
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
                    child: _content(context, clock, saving, choices),
                  ),
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
    List<(String, Duration)> choices,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      child: Column(
        children: <Widget>[
          ListenTarget(
            id: _questionPart,
            radius: 8,
            child: Text(
              context.tr('simplified_mode.when_remind'),
              textAlign: TextAlign.center,
              style: SimplifiedStyle.head(28, color: SimplifiedStyle.surface),
            ),
          ),
          const SizedBox(height: 16),
          const ListenButton(onDark: true),
          const SizedBox(height: 28),
          if (choices.isEmpty)
            ListenTarget(
              id: _nonePart,
              radius: 8,
              child: Text(
                context.tr('reminders.snooze_none'),
                textAlign: TextAlign.center,
                style: SimplifiedStyle.text(
                  SimplifiedStyle.body,
                  color: SimplifiedStyle.surface,
                ),
              ),
            ),
          for (final (String key, Duration after) in choices) ...<Widget>[
            ListenTarget(
              id: key,
              child: _Choice(
                label: context.tr(key),
                clock: clock(after),
                onTap: saving ? null : () => _choose(context, after),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          ListenTarget(
            id: _backPart,
            radius: 30,
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }
}

/// One choice, «بعد ١٥ دقيقة» over the clock time it means; a screen reader
/// hears both as one button. Disabled ([onTap] null) while one is saved.
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.clock, this.onTap});

  final String label;
  final String clock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(SimplifiedStyle.radius);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: sentences(<String>[label, clock]),
      excludeSemantics: true,
      child: Material(
        color: SimplifiedStyle.surface.withValues(alpha: .1),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 92,
              minWidth: double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: SimplifiedStyle.head(
                      SimplifiedStyle.headline,
                      color: SimplifiedStyle.surface,
                    ),
                  ),
                  Text(
                    clock,
                    textAlign: TextAlign.center,
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.caption,
                      color: SimplifiedStyle.onDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
