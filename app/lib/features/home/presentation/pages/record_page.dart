import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_history_section.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  String _selected = 'medications';

  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circle) =>
          BlocBuilder<MedicationsCubit, MedicationsState>(
            builder: (context, state) {
              final measurementPlans = context
                  .watch<MeasurementPlansCubit>()
                  .state
                  .plans;
              final header = Column(
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
                          circleId: circle.id,
                          plans: state.plans,
                        ),
                        icon: const Icon(CupertinoIcons.share),
                        label: Text(context.tr('record_export.share_action')),
                      ),
                    ],
                  ),
                  HomeCategoryControl(
                    medicationCount: state.plans.length,
                    measurementCount: measurementPlans.length,
                    showCounts: false,
                    selected: _selected,
                    onChanged: (value) => setState(() => _selected = value),
                  ),
                ],
              );
              if (_selected == 'measurements') {
                return MeasurementRecordSection(
                  circleId: circle.id,
                  header: header,
                  plans: measurementPlans,
                );
              }
              if (_selected == 'appointments') {
                return AppointmentRecordSection(
                  circleId: circle.id,
                  canManage: circle.canManageMedications,
                  header: header,
                );
              }
              return MedicationHistorySection(
                circleId: circle.id,
                header: header,
              );
            },
          ),
    );
  }
}
