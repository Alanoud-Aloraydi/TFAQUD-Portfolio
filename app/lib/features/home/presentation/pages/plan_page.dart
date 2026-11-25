import 'package:app/app/router/fading_branches.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_record_section.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_shell_lifecycle.dart';
import 'package:app/features/home/presentation/cubit/home_shell_wiring.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:app/features/home/presentation/widgets/home_shell_view.dart';
import 'package:app/features/home/presentation/widgets/record_header.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_first.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_section.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_history_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// The shell host of the four tabs: the bars, the circle switcher and what
/// the home data decides (sign-in ended, onboarding, no circle).
///
/// It only wires. The phone's side lives in small controllers: the data of
/// the shown circle (`ClinicalDataLoader`), the reminders and calendar
/// (`ReminderSync`) and the taps on a reminder (`NotificationTapHandler`).
class HomeFeatureScreen extends StatefulWidget {
  const HomeFeatureScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeFeatureScreen> createState() => _HomeFeatureScreenState();
}

class _HomeFeatureScreenState extends State<HomeFeatureScreen>
    with WidgetsBindingObserver, HomeResumeRefresh<HomeFeatureScreen> {
  @override
  late final HomeStateReactor reactor;

  @override
  void initState() {
    super.initState();
    reactor = createHomeStateReactor(
      context,
      widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant HomeFeatureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTab(context, reactor, widget.navigationShell.currentIndex);
  }

  @override
  void dispose() {
    reactor.dispose();
    super.dispose();
  }

  /// What every main tab does when pulled down from its top.
  Future<void> _refresh() => refreshNow(context, reactor);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return RefreshScope(
      onRefresh: _refresh,
      child: BlocConsumer<HomeCubit, HomeState>(
        listener: reactor.onState,
        builder: (context, state) =>
            homeShellView(context, state, cubit, widget.navigationShell),
      ),
    );
  }
}
