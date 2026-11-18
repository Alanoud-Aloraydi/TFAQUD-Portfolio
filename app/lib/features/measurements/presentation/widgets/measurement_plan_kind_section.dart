import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «القياس» of the plan form: the kind to choose for a new plan.
///
/// The kind is chosen once, when the plan is made: an existing plan's
/// readings belong to it. Editing shows it as a fact, not as a control that
/// looks tappable and is not.
class MeasurementPlanKindSection extends StatelessWidget {
  const MeasurementPlanKindSection({
    super.key,
    required this.kind,
    required this.isNew,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final bool isNew;
  final ValueChanged<MeasurementKind> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!isNew) {
      return InsetGroup(
        children: <Widget>[
          InfoRow(
            label: context.tr('measurements.measurement'),
            value: measurementKindTitle(context, kind),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
          child: Text(
            context.tr('measurements.measurement'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassSegmentedControl<MeasurementKind>(
          segments: <MeasurementKind, String>{
            MeasurementKind.glucose: context.tr('measurements.glucose'),
            MeasurementKind.bp: context.tr('measurements.bp'),
          },
          selected: kind,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
