import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_section.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_plans_section.dart';
import 'package:easy_localization/easy_localization.dart';
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
              final clock = PatientClockScope.of(context);
              final today = clock.today();
              final count = state.plans
                  .where((plan) => !plan.isPreviousOn(today))
                  .length;
              final measurements = context
                  .watch<MeasurementPlansCubit>()
                  .state
                  .plans
                  .where((plan) => plan.stoppedAt == null)
                  .length;
              final appointments = context
                  .watch<AppointmentsCubit>()
                  .state
                  .appointments
                  .where(
                    (item) =>
                        item.status == AppointmentStatus.scheduled &&
                        !item.scheduledAt.isBefore(clock.now()),
                  )
                  .length;
              final header = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LargeTitle(
                    title: context.tr('tab.plan'),
                    subtitle: CareVoice.tr(
                      context,
                      circle.id,
                      'medications.plan_subtitle',
                    ),
                  ),
                  HomeCategoryControl(
                    counts: {
                      HomeCategory.medications: count,
                      HomeCategory.measurements: measurements,
                      HomeCategory.appointments: appointments,
                    },
                    selected: category,
                    onChanged: selectCategory,
                  ),
                ],
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
                    canManage: circle.canManageMedications,
                    header: header,
                  ),
                  AppointmentPlanSection(
                    circleId: circle.id,
                    canManage: circle.canManageMedications,
                    header: header,
                  ),
                ],
              );
            },
          ),
    );
  }
}
