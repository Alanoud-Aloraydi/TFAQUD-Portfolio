import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/add_member_button.dart';
import 'package:app/features/circles/presentation/widgets/circle_card.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tiles.dart';
import 'package:app/features/circles/presentation/widgets/circle_members_header.dart';
import 'package:app/features/circles/presentation/widgets/circle_members_list.dart';
import 'package:app/features/circles/presentation/widgets/circle_overview_failure.dart';
import 'package:app/features/circles/presentation/widgets/leave_circle_button.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
