import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/reading_number_field.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A reading outside its normal range in the attention box: its value,
/// level and range, and «تابعتها».
class OutsideReadingCard extends StatelessWidget {
  const OutsideReadingCard({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) {
    return MeasurementAttentionCard(
      kind: reading.kind,
      title: ReadingTitles(reading: reading),
      status: ReadingValue(reading: reading),
      lines: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ReadingStatusPill(reading: reading),
        ),
        if (reading.range != null)
          Text(
            readingRangeText(context, reading),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
      actions: <Widget>[ReadingFollowUpButton(reading: reading)],
    );
  }
}

/// «تابعتها» under a reading outside its normal range, in the buttons every
/// task shares (TaskButtonRole): it records that someone followed it up.
class ReadingFollowUpButton extends StatelessWidget {
  const ReadingFollowUpButton({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) => TaskButtonGrid(
    answer: TaskButton(
      role: TaskButtonRole.answer,
      icon: CupertinoIcons.checkmark,
      label: context.tr('measurements.follow_up'),
      onPressed: () => _followUp(context),
    ),
  );

  Future<void> _followUp(BuildContext context) async {
    final String? messageKey = await context
        .read<MeasurementReadingsCubit>()
        .followUp(reading);
    if (!context.mounted) return;
    if (messageKey == null) {
      AppToast.show(context, 'toast.follow_up_done');
    } else {
      showMeasurementMessage(context, messageKey);
    }
  }
}
