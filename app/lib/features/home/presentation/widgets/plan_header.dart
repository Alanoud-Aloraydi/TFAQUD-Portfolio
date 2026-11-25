import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/home/presentation/widgets/home_shell_view.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The top of every «الخطة» list: the title and the control that picks the
/// kind, each kind with how many it holds now.
class PlanHeader extends StatelessWidget {
  const PlanHeader({
    super.key,
    required this.circleId,
    required this.medicationPlans,
    required this.category,
    required this.onChanged,
  });

  final String circleId;
  final List<MedicationPlan> medicationPlans;
  final HomeCategory category;
  final ValueChanged<HomeCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final clock = PatientClockScope.of(context);
    final today = clock.today();
    final count = medicationPlans
        .where((plan) => !plan.isPreviousOn(today))
        .length;
    final measurements = context
        .watch<MeasurementPlansCubit>()
        .state
        .plans
        .where((plan) => plan.stoppedAt == null)
        .length;
    final appointments = upcomingBookings(
      context.watch<AppointmentsCubit>().state.appointments,
      clock.now(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LargeTitle(
          title: context.tr('tab.plan'),
          subtitle: CareVoice.tr(
            context,
            circleId,
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
          onChanged: onChanged,
        ),
      ],
    );
  }
}
