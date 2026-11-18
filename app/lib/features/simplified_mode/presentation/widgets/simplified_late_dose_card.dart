import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_answers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// A dose whose time passed unrecorded: ask, and offer to record it now.
class SimplifiedLateDoseCard extends StatelessWidget {
  const SimplifiedLateDoseCard({
    super.key,
    required this.task,
    required this.day,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «سأذكّرك 2:09 مساءً» when the dose is put off.
  final String? snoozed;

  @override
  Widget build(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (cubit) => cubit.state.saving,
    );
    return SimplifiedCard(
      color: SimplifiedColors.attention,
      side: const BorderSide(color: SimplifiedColors.attentionBorder),
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 24,
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            label: spoken(simplifiedLateDoseSaid(context, task, day, snoozed)),
            excludeSemantics: true,
            child: SimplifiedLateDoseText(
              task: task,
              day: day,
              snoozed: snoozed,
            ),
          ),
          const SizedBox(height: 16),
          SimplifiedLateDoseAnswers(task: task, saving: saving),
        ],
      ),
    );
  }
}
