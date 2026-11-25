import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
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
