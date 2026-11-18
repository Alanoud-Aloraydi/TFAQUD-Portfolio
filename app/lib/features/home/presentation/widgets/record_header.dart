import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The top of every «السجل» list: the title, the button that shares the
/// record as a file, and the control that picks the kind.
class RecordHeader extends StatelessWidget {
  const RecordHeader({
    super.key,
    required this.circleId,
    required this.plans,
    required this.measurementPlans,
    required this.category,
    required this.onChanged,
  });

  final String circleId;
  final List<MedicationPlan> plans;
  final List<MeasurementPlan> measurementPlans;
  final HomeCategory category;
  final ValueChanged<HomeCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: LargeTitle(
                title: context.tr('tab.record'),
                subtitle: context.tr('record_export.tab_subtitle'),
              ),
            ),
            TextButton.icon(
              onPressed: () => showRecordExportSheet(
                context,
                circleId: circleId,
                plans: plans,
                measurementPlans: measurementPlans,
              ),
              icon: const Icon(CupertinoIcons.share),
              label: Text(context.tr('record_export.share_action')),
            ),
          ],
        ),
        HomeCategoryControl(
          counts: const {},
          showCounts: false,
          selected: category,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
