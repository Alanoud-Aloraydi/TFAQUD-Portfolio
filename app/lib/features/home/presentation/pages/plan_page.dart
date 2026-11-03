import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_plans_section.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  String _selected = 'medications';

  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circle) =>
          BlocBuilder<MedicationsCubit, MedicationsState>(
            builder: (context, state) {
              final today = DateUtils.dateOnly(DateTime.now());
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
                        !item.scheduledAt.isBefore(DateTime.now()),
                  )
                  .length;
              final header = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LargeTitle(
                    title: context.tr('tab.plan'),
                    subtitle: context.tr('medications.plan_subtitle'),
                  ),
                  HomeCategoryControl(
                    medicationCount: count,
                    measurementCount: measurements,
                    appointmentCount: appointments,
                    selected: _selected,
                    onChanged: (value) => setState(() => _selected = value),
                  ),
                ],
              );
              if (_selected == 'measurements') {
                return MeasurementPlanSection(
                  circleId: circle.id,
                  canManage: circle.canManageMedications,
                  header: header,
                );
              }
              if (_selected == 'appointments') {
                return AppointmentPlanSection(
                  circleId: circle.id,
                  canManage: circle.canManageMedications,
                  header: header,
                );
              }
              return MedicationPlansSection(
                circleId: circle.id,
                header: header,
              );
            },
          ),
    );
  }
}
