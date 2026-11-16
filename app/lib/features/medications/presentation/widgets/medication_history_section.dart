import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_history_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «السجل»'s medicines: the plans of [circleId] that are already behind.
/// The tab is the record, so it holds what has been; the running
/// medicines are «الخطة»'s, and a filter between the two offered a
/// choice that was empty on one side or the other.
class MedicationHistorySection extends StatelessWidget {
  const MedicationHistorySection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
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
        child: MedicationHistoryContent(
          circleId: circleId,
          header: header,
          state: state,
        ),
      ),
    );
  }
}
