import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/medication_record_filter.dart';
import 'package:app/features/medications/presentation/widgets/medication_history_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «السجل»'s medicines: the plans of [circleId], filtered by the choice
/// this section keeps for itself — the filter picks among plans already
/// loaded, so it is the page's state, not the cubit's.
///
/// It opens on «السابقة», what the tab's name promises: a record is what
/// has been. «الحالية» is «الخطة»'s job, and opening on «الكل» showed the
/// running medicines first, so the two tabs read the same.
class MedicationHistorySection extends StatefulWidget {
  const MedicationHistorySection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
  final Widget header;

  @override
  State<MedicationHistorySection> createState() =>
      _MedicationHistorySectionState();
}

class _MedicationHistorySectionState extends State<MedicationHistorySection> {
  MedicationRecordFilter _filter = MedicationRecordFilter.previous;

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
          circleId: widget.circleId,
          header: widget.header,
          state: state,
          filter: _filter,
          onFilterChanged: (value) => setState(() => _filter = value),
        ),
      ),
    );
  }
}
