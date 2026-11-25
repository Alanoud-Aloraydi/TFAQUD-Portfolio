import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/leave_circle_alert.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_header.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';

/// «مغادرة الدائرة»: for the last manager and the patient it deletes the
/// circle instead, after a confirmation. A member whose editing is paused
/// can leave too.
class LeaveCircleButton extends StatelessWidget {
  const LeaveCircleButton({super.key, required this.overview});

  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final bool acting = context.select(
      (CircleOverviewCubit cubit) => cubit.state.acting,
    );
    return TextButton.icon(
      onPressed: acting ? null : () => _leave(context),
      style: TextButton.styleFrom(
        foregroundColor: AppSemanticColors.statusError,
        minimumSize: const Size.fromHeight(AppSizes.button),
      ),
      icon: const Icon(ActionIcons.signOut, size: AppSizes.iconSmall),
      label: Text(context.tr('circle_overview.leave')),
    );
  }

  Future<void> _leave(BuildContext context) async {
    final bool deletesCircle = overview.leaveDeletesCircle;
    final String circleId = context.read<CircleOverviewCubit>().circleId;
    final LeaveCircleChoice? choice = await askLeaveConfirmation(
      context,
      deletesCircle,
    );
    if (!context.mounted ||
        choice == null ||
        choice == LeaveCircleChoice.cancel) {
      return;
    }
    if (choice == LeaveCircleChoice.export) {
      await exportBeforeLeaving(context, circleId);
      return;
    }
    final String? error = await context.read<CircleOverviewCubit>().leave(
      confirmDelete: deletesCircle,
    );
    if (!context.mounted) return;
    if (error != null) {
      AppToast.show(context, error, kind: ToastKind.error);
      return;
    }
    await context.read<HomeCubit>().refresh();
    if (!context.mounted) return;
    AppToast.show(context, 'toast.circle_left');
    context.go(Routes.today);
  }
}

/// Opens the record export with what this circle has, so its data can be
/// taken out before the circle goes. The circle is not left: the person
/// taps «مغادرة الدائرة» again once the file is saved.
Future<void> exportBeforeLeaving(BuildContext context, String circleId) async {
  final Result<List<MedicationPlan>, Failure> plans = await GetIt.I
      .get<MedicationsUseCase>()
      .getPlans(circleId);
  final List<MeasurementPlan> measurementPlans = await GetIt.I
      .get<MeasurementsUseCase>()
      .plans(circleId);
  if (!context.mounted) return;
  final Failure? failure = plans.tryGetError();
  if (failure != null) {
    AppToast.show(context, failure.messageKey, kind: ToastKind.error);
    return;
  }
  await showRecordExportSheet(
    context,
    circleId: circleId,
    plans: plans.tryGetSuccess()!,
    measurementPlans: measurementPlans,
  );
}
