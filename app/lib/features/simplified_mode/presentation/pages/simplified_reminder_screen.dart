import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_close_bar.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            backgroundColor: SimplifiedStyle.reminderGround,
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
