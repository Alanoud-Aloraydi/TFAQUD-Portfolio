import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/usecases/visits_use_case.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/repositories/record_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/widgets/home_shell_view.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_body.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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

Future<void> showRecordExportSheet(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
  required List<MeasurementPlan> measurementPlans,
}) => showGlassSheet<void>(
  context,
  title: context.tr('record_export.title'),
  message: context.tr('record_export.subtitle'),
  builder: (_) => BlocProvider(
    create: (_) => RecordExportCubit(
      GetIt.I<CirclesUseCase>(),
      GetIt.I<RecordExporter>(),
      GetIt.I<MeasurementsUseCase>(),
      GetIt.I<MedicationsUseCase>(),
      GetIt.I<AppointmentsUseCase>(),
      GetIt.I<VisitsUseCase>(),
      circleId,
    )..load(),
    child: RecordExportSheetBody(
      plans: List.unmodifiable(plans),
      measurementPlans: List.unmodifiable(measurementPlans),
    ),
  ),
);
