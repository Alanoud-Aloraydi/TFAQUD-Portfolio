import 'package:app/core/navigation/routers.dart';
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

  static const List<(String, Duration)> _choices = <(String, Duration)>[
    ('simplified_mode.after_15', Duration(minutes: 15)),
    ('simplified_mode.after_30', Duration(minutes: 30)),
    ('simplified_mode.after_60', Duration(hours: 1)),
  ];

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
                child: IntrinsicHeight(child: _content(context, clock, saving)),
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
          const SizedBox(height: 16),
          const SizedBox(height: 28),
          for (final (String key, Duration after) in _choices) ...<Widget>[
            SimplifiedSnoozeChoice(
              label: context.tr(key),
              clock: clock(after),
              onTap: saving ? null : () => _choose(context, after),
            ),
            const SizedBox(height: 12),
          ],
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
