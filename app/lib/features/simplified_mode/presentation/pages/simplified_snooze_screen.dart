import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/simplified_voice.dart';
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

/// «متى أذكّرك؟»: three big choices, each with the clock time it means.
class SimplifiedSnoozeScreen extends StatelessWidget {
  const SimplifiedSnoozeScreen({super.key, required this.kind});

  /// A dose or a measurement; appointments are not put off.
  final TodayTaskKind kind;

  static const List<(String, Duration)> _choices = <(String, Duration)>[
    ('simplified_mode.after_15', Duration(minutes: 15)),
    ('simplified_mode.after_30', Duration(minutes: 30)),
    ('simplified_mode.after_60', Duration(hours: 1)),
  ];

  Future<void> _choose(BuildContext context, Duration after) async {
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    final TodayTask? task = cubit.state.schedule?.taskToRecord(kind);
    final String name = task == null
        ? context.tr('simplified_mode.kind.${kind.name}')
        : simplifiedTaskTitle(context, task);
    await cubit.snooze(
      kind: kind,
      title: context.tr('simplified_mode.snooze_title', args: <String>[name]),
      body: context.tr('simplified_mode.snooze_body'),
      after: after,
    );
    if (context.mounted) context.go(Routes.simplifiedMode);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = context.select<SimplifiedModeCubit, DateTime>(
      (cubit) => cubit.state.now,
    );
    String clock(Duration after) => simplifiedClockAt(context, now.add(after));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SimplifiedStyle.reminderGround,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
            child: Column(
              children: <Widget>[
                ListenTarget(
                  id: _questionPart,
                  radius: 8,
                  child: Text(
                    context.tr('simplified_mode.when_remind'),
                    style: SimplifiedStyle.head(
                      28,
                      color: SimplifiedStyle.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListenButton(
                  onDark: true,
                  parts: <SpokenPart>[
                    (
                      id: _questionPart,
                      text: context.tr('simplified_mode.when_remind'),
                    ),
                    for (final (String key, Duration after) in _choices)
                      (
                        id: key,
                        text: sentences(<String>[
                          context.tr(key),
                          clock(after),
                        ]),
                      ),
                    (id: _backPart, text: context.tr('simplified_mode.back')),
                  ],
                ),
                const SizedBox(height: 28),
                for (final (String key, Duration after)
                    in _choices) ...<Widget>[
                  ListenTarget(
                    id: key,
                    child: Material(
                      color: SimplifiedStyle.surface.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(
                        SimplifiedStyle.radius,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          SimplifiedStyle.radius,
                        ),
                        onTap: () => _choose(context, after),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 92),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    context.tr(key),
                                    style: SimplifiedStyle.head(
                                      SimplifiedStyle.headline,
                                      color: SimplifiedStyle.surface,
                                    ),
                                  ),
                                  Text(
                                    clock(after),
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
          ),
        ),
      ),
    );
  }
}
