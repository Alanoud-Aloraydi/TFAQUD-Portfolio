import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_plan_section.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/plan_header.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_section.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_plans_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «الخطة»: the medicines, measurement plans and appointments of the shown
/// circle, one kind at a time.
class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage>
    with HomeCategorySelection<PlanPage> {
  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circle) =>
          BlocBuilder<MedicationsCubit, MedicationsState>(
            builder: (context, state) {
              final header = PlanHeader(
                circleId: circle.id,
                medicationPlans: state.plans,
                category: category,
                onChanged: selectCategory,
              );
              return FadingBranches(
                currentIndex: category.index,
                children: [
                  MedicationPlansSection(
                    circleId: circle.id,
                    canManage: circle.canManageMedications,
                    header: header,
                  ),
                  MeasurementPlanSection(
                    circleId: circle.id,
                    canManage: circle.canManageMeasurements,
                    header: header,
                  ),
                  AppointmentPlanSection(
                    circleId: circle.id,
                    canManage: circle.canManageAppointments,
                    header: header,
                  ),
                ],
              );
            },
          ),
    );
  }
}
