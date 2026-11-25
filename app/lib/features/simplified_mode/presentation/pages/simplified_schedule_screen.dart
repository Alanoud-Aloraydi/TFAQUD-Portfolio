import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_schedule_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «جدول اليوم»: today's tasks in time order, under the prayer they follow.
class SimplifiedScheduleScreen extends StatefulWidget {
  const SimplifiedScheduleScreen({super.key});

  @override
  State<SimplifiedScheduleScreen> createState() =>
      _SimplifiedScheduleScreenState();
}

class _SimplifiedScheduleScreenState extends State<SimplifiedScheduleScreen> {
  /// Null shows every kind («الكل»).
  TodayTaskKind? _filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimplifiedModeCubit, SimplifiedModeState>(
      builder: (context, state) {
        final SimplifiedDay? day = state.day;
        return SimplifiedPage(
          title: context.tr('simplified_mode.schedule_title'),
          children: <Widget>[
            if (day == null)
              const LoadingNote()
            else
              SimplifiedScheduleCard(
                day: day,
                state: state,
                filter: _filter,
                onFilterChanged: (value) => setState(() => _filter = value),
              ),
          ],
        );
      },
    );
  }
}
