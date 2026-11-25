import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The full-screen reminder a tapped notification or a home card opens,
/// for a dose, a reading or a visit alike. Like a call: one calm dark
/// colour, the task's picture, and one or two big round answers.
class SimplifiedReminderScreen extends StatelessWidget {
  const SimplifiedReminderScreen({super.key, required this.request});

  /// The task it asks about; while it waits, it is shown live from the day.
  final ReminderRequest request;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SimplifiedModeCubit, SimplifiedModeState>(
        builder: (context, state) {
          final SimplifiedReminderContent? content = reminderContent(
            context,
            request,
            state,
          );
          return Scaffold(
            backgroundColor: SimplifiedColors.reminderGround,
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  const SimplifiedReminderCloseBar(),
                  Expanded(
                    child: content == null
                        ? const SimplifiedReminderNothingWaiting()
                        : SimplifiedReminderBody(content: content),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

/// «إغلاق» at the top: back to where the reminder opened over, answering
/// nothing, so the task stays as it was.
class SimplifiedReminderCloseBar extends StatelessWidget {
  const SimplifiedReminderCloseBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
        child: TextButton.icon(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.simplifiedMode),
          icon: const Icon(ActionIcons.x, size: 26),
          label: Text(
            context.tr('simplified_mode.close'),
            style: SimplifiedStyle.label(
              SimplifiedStyle.body,
              color: SimplifiedColors.surface,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: SimplifiedColors.surface,
            minimumSize: const Size(0, SimplifiedStyle.touch),
          ),
        ),
      ),
    );
  }
}

/// The reminder itself: the picture first and as big as the screen
/// allows, the words under it, the answers at the bottom.
class SimplifiedReminderBody extends StatelessWidget {
  const SimplifiedReminderBody({super.key, required this.content});

  final SimplifiedReminderContent content;

  /// What the words and the answers need under the picture.
  static const double _rest = 440;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // The picture takes what is left, never smaller than a medicine's
      // box reads at, never so tall the answers leave the screen.
      final double hero = (box.maxHeight - _rest).clamp(180.0, 340.0);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: <Widget>[
                  SimplifiedReminderHero(
                    height: hero,
                    child: content.hero(hero),
                  ),
                  const SizedBox(height: 24),
                  SimplifiedReminderWords(content: content),
                  const Spacer(),
                  const SizedBox(height: 24),
                  SimplifiedReminderAnswers(content: content),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// The reminder's one picture: as wide as the screen, in the honey edge,
/// big enough to know the medicine by its box from across the room.
/// Decorative: the words under it name the task.
class SimplifiedReminderHero extends StatelessWidget {
  const SimplifiedReminderHero({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: SimplifiedColors.muted,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SimplifiedColors.attentionEdge, width: 5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

/// What the reminder asks, read as one sentence: «حان وقت»، the task's
/// name, its line, who comes along, and its short notes.
class SimplifiedReminderWords extends StatelessWidget {
  const SimplifiedReminderWords({super.key, required this.content});

  final SimplifiedReminderContent content;

  static const Color _ink = SimplifiedColors.surface;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      children: <Widget>[
        Text(content.lead, style: SimplifiedStyle.text(28, color: _ink)),
        Text(
          content.name,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.hero, color: _ink),
        ),
        const SizedBox(height: 10),
        Text(
          content.line,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.headline, color: _ink),
        ),
        if (content.people case final Widget people) ...<Widget>[
          const SizedBox(height: 12),
          people,
        ],
        if (content.chips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final String chip in content.chips)
                SimplifiedChip(chip, onDark: true),
            ],
          ),
        ],
      ],
    ),
  );
}

/// The reminder's one or two round answers: the task's own («أخذته»,
/// «حضرت») and, when it can be put off, «ذكّرني لاحقًا».
class SimplifiedReminderAnswers extends StatelessWidget {
  const SimplifiedReminderAnswers({super.key, required this.content});

  final SimplifiedReminderContent content;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SimplifiedReminderRoundAnswer(
        label: content.yesLabel,
        icon: ActionIcons.check,
        fill: SimplifiedColors.accent,
        ink: SimplifiedColors.ink,
        onTap: content.onYes,
      ),
      if (content.onLater case final VoidCallback later) ...<Widget>[
        const SizedBox(width: 16),
        SimplifiedReminderRoundAnswer(
          label: context.tr('simplified_mode.remind_later'),
          icon: ScheduleIcons.clock,
          fill: SimplifiedColors.surface.withValues(alpha: .24),
          ink: SimplifiedColors.surface,
          onTap: later,
        ),
      ],
    ],
  );
}
