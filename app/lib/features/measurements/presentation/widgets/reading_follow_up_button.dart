import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «تابعتها» under a reading outside its normal range, in the buttons every
/// task shares (TaskButtonRole): it records that someone followed it up.
class ReadingFollowUpButton extends StatelessWidget {
  const ReadingFollowUpButton({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) => TaskButtonGrid(
    buttons: <Widget>[
      TaskButton(
        role: TaskButtonRole.answer,
        icon: CupertinoIcons.checkmark,
        label: context.tr('measurements.follow_up'),
        onPressed: () => _followUp(context),
      ),
    ],
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
