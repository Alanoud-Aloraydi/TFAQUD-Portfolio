import 'package:app/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// «الخطة»'s measurements: the active plans of [circleId], editable and
/// stoppable when [canManage], read again after a change saved anywhere.
class MeasurementPlanSection extends StatelessWidget {
  const MeasurementPlanSection({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    // The normal ranges the opened details show, read once for the circle.
    return BlocProvider<MeasurementRangesCubit>(
      key: ValueKey<String>('measurement-ranges-$circleId'),
      create: (_) =>
          MeasurementRangesCubit(GetIt.I<MeasurementRepository>())
            ..load(circleId),
      child: MeasurementPlanList(
        circleId: circleId,
        canManage: canManage,
        header: header,
      ),
    );
  }
}
