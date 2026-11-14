import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_card.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile.dart';
import 'package:app/features/circles/presentation/widgets/circle_members_header.dart';
import 'package:app/features/circles/presentation/widgets/circle_members_list.dart';
import 'package:app/features/circles/presentation/widgets/invite_member_sheet.dart';
import 'package:app/features/circles/presentation/widgets/leave_circle_button.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The "الدائرة" tab (CIRCLE-01): who the circle cares for and who shares
/// it. From the top: the patient card, the two tiles that open the medical
/// file and the emergency card, the members with the pending invitations,
/// «إضافة عضو» and «مغادرة الدائرة». Needs the [HomeCubit] of the home
/// screen above it.
class CircleTabScreen extends StatelessWidget {
  const CircleTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (BuildContext context, HomeState state) {
        final String? selectedId = state.selectedCircleId;
        CareCircleSummary? circle;
        for (final CareCircleSummary candidate
            in state.data?.circles ?? const <CareCircleSummary>[]) {
          if (candidate.id == selectedId) circle = candidate;
        }
        if (circle == null) return const SizedBox.shrink();
        return BlocProvider(
          key: ValueKey(selectedId),
          create: (_) => CircleOverviewCubit(
            GetIt.I<CirclesUseCase>(),
            selectedId!,
            GetIt.I<PrivatePhotoRepository>().changes,
          )..load(),
          child: _CircleContent(circle: circle),
        );
      },
    );
  }
}

/// Renders the circle content element of circle tab screen.
class _CircleContent extends StatelessWidget {
  const _CircleContent({required this.circle});

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
            const Center(child: CupertinoActivityIndicator())
          else if (state.status == CircleOverviewStatus.failure)
            Column(
              children: <Widget>[
                Text(
                  context.tr(state.errorKey ?? 'error.unknown'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: context.read<CircleOverviewCubit>().load,
                  child: Text(context.tr('auth.retry')),
                ),
              ],
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
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: CircleFeatureTile(
                icon: AppIcons.fileText,
                iconColor: AppSemanticColors.textSupporting,
                title: context.tr('circles.file_title'),
                // A file with unknown answers says so, with the yellow «!».
                subtitle: (medicalFile?.needsFilling ?? false)
                    ? context.tr('medical_alert.tile')
                    : context.tr('circle_overview.file_hint'),
                attention: medicalFile?.needsFilling ?? false,
                onTap: () => context.push(Routes.medicalFile(circle.id)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CircleFeatureTile(
                icon: AppIcons.firstAid,
                iconColor: AppSemanticColors.statusError,
                title: context.tr('circles.card_title'),
                subtitle: context.tr('circle_overview.card_hint'),
                onTap: () => context.push(Routes.emergencyCard(circle.id)),
              ),
            ),
          ],
        ),
      ),
      CircleMembersHeader(overview: overview),
      CircleMembersList(overview: overview, circleId: circle.id),
      if (overview.canManage) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: state.acting ? null : () => _invite(context),
          icon: const Icon(AppIcons.userPlus, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.add_member')),
        ),
      ],
      if (overview.canLeave) ...<Widget>[
        const SizedBox(height: AppSpacing.sm),
        LeaveCircleButton(overview: overview),
      ],
    ];
  }

  void _invite(BuildContext context) {
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    showGlassSheet<void>(
      context,
      title: context.tr('circle_overview.add_member'),
      message: context.tr('circle_overview.invite_hint'),
      builder: (_) => InviteMemberSheet(cubit: cubit),
    );
  }
}
