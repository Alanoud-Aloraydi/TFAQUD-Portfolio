import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «تغيير الحالة في الملف الطبي» under a normal range, on the plan's form
/// and on a reading alike: the condition a range follows is the medical
/// file's, so it is changed there. On the way back the ranges are read
/// again through the [MeasurementRangesCubit] above, as a changed condition
/// changes them.
class ConditionFileRow extends StatelessWidget {
  const ConditionFileRow({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) => InsetRow(
    label: context.tr('measurements.change_condition'),
    leading: const Icon(CareIcons.fileText),
    showChevron: true,
    onTap: () => _open(context),
  );

  Future<void> _open(BuildContext context) async {
    final MeasurementRangesCubit cubit = context.read<MeasurementRangesCubit>();
    await context.push(Routes.medicalFile(circleId));
    if (!cubit.isClosed) await cubit.load(circleId);
  }
}
