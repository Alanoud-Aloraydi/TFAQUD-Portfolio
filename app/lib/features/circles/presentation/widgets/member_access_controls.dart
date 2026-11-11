import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/member_access_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The owner's controls over one member: whether they may edit, and removing
/// them from the circle. Disabled while another change is on its way.
class MemberAccessControls extends StatelessWidget {
  const MemberAccessControls({super.key, required this.member});

  final CircleMember member;

  @override
  Widget build(BuildContext context) {
    final bool acting = context.select(
      (CircleOverviewCubit cubit) => cubit.state.acting,
    );
    final String? accountId = member.accountId;
    final bool enabled = !acting && accountId != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.tr('circle_overview.allow_editing'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Switch.adaptive(
              value: member.canEdit,
              onChanged: enabled
                  ? (bool value) =>
                        changeMemberAccess(context, accountId, canEdit: value)
                  : null,
            ),
          ],
        ),
        IconButton(
          tooltip: context.tr('circle_overview.remove_member'),
          onPressed: enabled
              ? () => confirmRemoveMember(context, member, accountId)
              : null,
          icon: const Icon(CupertinoIcons.trash),
          color: AppSemanticColors.statusError,
        ),
      ],
    );
  }
}
