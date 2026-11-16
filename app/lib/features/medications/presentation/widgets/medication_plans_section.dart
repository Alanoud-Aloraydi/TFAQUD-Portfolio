import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_plans_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «الأدوية» on the plan tab: the list, with a fade between loading, a
/// failure and the medicines themselves.
class MedicationPlansSection extends StatelessWidget {
  const MedicationPlansSection({
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
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) => ContentSwitcher(
        // Only loading, error and content fade; saving a change does not.
        stateKey: switch (state.status) {
          MedicationsStatus.initial || MedicationsStatus.loading => 'loading',
          MedicationsStatus.failure => 'failure',
          _ => 'content',
        },
        child: MedicationPlansContent(
          circleId: circleId,
          canManage: canManage,
          header: header,
          state: state,
        ),
      ),
    );
  }
}
