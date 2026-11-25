import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_card.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tiles.dart';
import 'package:app/features/circles/presentation/widgets/circle_invitation_row.dart';
import 'package:app/features/circles/presentation/widgets/circle_member_row.dart';
import 'package:app/features/circles/presentation/widgets/circle_members_header.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_header.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';

/// Renders the circle content element of circle tab screen.
class CircleContent extends StatelessWidget {
  const CircleContent({super.key, required this.circle});

  final CareCircleSummary circle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleOverviewCubit, CircleOverviewState>(
      builder: (BuildContext context, CircleOverviewState state) => ListView(
        padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
        children: <Widget>[
          LargeTitle(
            title: context.tr('tab.circle'),
            subtitle: context.tr('circle_overview.subtitle'),
          ),
          if (state.status == CircleOverviewStatus.loading)
            const LoadingNote()
          else if (state.status == CircleOverviewStatus.failure)
            CircleOverviewFailure(
              errorKey: state.errorKey,
              onRetry: context.read<CircleOverviewCubit>().load,
            )
          else
            ..._ready(context, state),
        ],
      ),
    );
  }

  List<Widget> _ready(BuildContext context, CircleOverviewState state) {
    final CircleOverview overview = state.overview!;
    final MedicalFile? medicalFile = state.medicalFile;
    return <Widget>[
      CircleCard(circle: circle, overview: overview, medicalFile: medicalFile),
      const SizedBox(height: AppSpacing.md),
      CircleFeatureTiles(circleId: circle.id, medicalFile: medicalFile),
      CircleMembersHeader(overview: overview),
      CircleMembersList(overview: overview, circleId: circle.id),
      if (overview.canManage) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        AddMemberButton(acting: state.acting),
      ],
      if (overview.canLeave) ...<Widget>[
        const SizedBox(height: AppSpacing.sm),
        LeaveCircleButton(overview: overview),
      ],
    ];
  }
}

/// The circle could not be read: why, and a button that reads it again.
class CircleOverviewFailure extends StatelessWidget {
  const CircleOverviewFailure({
    super.key,
    required this.errorKey,
    required this.onRetry,
  });

  final String? errorKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          context.tr(errorKey ?? 'error.unknown'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
      ],
    );
  }
}

/// The members, then the pending invitations, in one slate group with
/// lines between the rows.
class CircleMembersList extends StatelessWidget {
  const CircleMembersList({
    super.key,
    required this.overview,
    required this.circleId,
  });

  final CircleOverview overview;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[
      for (final CircleMember member in overview.members)
        CircleMemberRow(
          member: member,
          circleId: circleId,
          patientUsesApp: overview.patientUsesApp,
          patientIsYou: overview.patientIsYou,
          canManageMembers: overview.canManageMembers,
          canHandOver: overview.canHandOver,
        ),
      for (final CirclePendingInvitation invitation
          in overview.pendingInvitations)
        CircleInvitationRow(
          invitation: invitation,
          canManage: overview.canManage,
        ),
    ];
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              if (i > 0)
                const Divider(
                  height: AppSizes.divider,
                  color: AppSemanticColors.borderPlan,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

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

/// What the person chose in the leave alert.
enum LeaveCircleChoice {
  /// Nothing happens.
  cancel,

  /// Take the record out first; the circle is not left.
  export,

  /// Leave, which deletes the circle when they are its patient or its last
  /// member.
  leave,
}

/// Asks to confirm leaving the circle, or deleting it when the person
/// leaving is its patient or its last member.
///
/// Leaving deletes the data with it, so that alert also offers to export
/// the record first; the ordinary one has nothing to save.
Future<LeaveCircleChoice?> askLeaveConfirmation(
  BuildContext context,
  bool deletesCircle,
) {
  final String kind = deletesCircle ? 'delete' : 'leave';
  return showAppAlert<LeaveCircleChoice>(
    context,
    title: context.tr('circle_overview.${kind}_title'),
    message: context.tr('circle_overview.${kind}_message'),
    actions: <AppAlertAction<LeaveCircleChoice>>[
      AppAlertAction<LeaveCircleChoice>(
        label: context.tr('common.cancel'),
        value: LeaveCircleChoice.cancel,
      ),
      if (deletesCircle)
        AppAlertAction<LeaveCircleChoice>(
          label: context.tr('circle_overview.export_before_leaving'),
          value: LeaveCircleChoice.export,
        ),
      AppAlertAction<LeaveCircleChoice>(
        label: context.tr(
          deletesCircle
              ? 'circle_overview.delete_confirm'
              : 'circle_overview.leave',
        ),
        value: LeaveCircleChoice.leave,
        destructive: true,
      ),
    ],
  );
}
