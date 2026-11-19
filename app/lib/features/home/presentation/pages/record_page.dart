import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_record_section.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/record_header.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_section.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «السجل»: the history of the medicines, the readings and the visits of the
/// shown circle, one kind at a time, and the way to share it as a file.
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage>
    with HomeCategorySelection<RecordPage> {
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
              final header = RecordHeader(
                circleId: circle.id,
                plans: state.plans,
                measurementPlans: measurementPlans,
                category: category,
                onChanged: selectCategory,
              );
              return FadingBranches(
                currentIndex: category.index,
                children: [
                  MedicationHistorySection(
                    circleId: circle.id,
                    header: header,
                    canManage: circle.canManageMedications,
                  ),
                  MeasurementRecordSection(
                    circleId: circle.id,
                    header: header,
                    // The same sheet as «سجّل قراءة الآن» in the add sheet.
                    onAddReading: circle.canRecord
                        ? () => showMeasurementReadingSheet(context)
                        : null,
                  ),
                  AppointmentRecordSection(
                    circleId: circle.id,
                    header: header,
                    canManage: circle.canManageAppointments,
                  ),
                ],
              );
            },
          ),
    );
  }
}
