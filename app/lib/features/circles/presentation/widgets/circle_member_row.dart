import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/member_access_buttons.dart';
import 'package:app/features/circles/presentation/widgets/member_open_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One member of the circle. Tapping the viewer's own row opens their
/// account; any other row opens that member's card, to call them. The
/// circle's leader ([canManageMembers]) has, under every other member, what
/// they decide about them ([MemberAccessControls]).
class CircleMemberRow extends StatelessWidget {
  const CircleMemberRow({
    super.key,
    required this.member,
    required this.circleId,
    required this.patientUsesApp,
    required this.patientIsYou,
    required this.canManageMembers,
    this.canHandOver = false,
  });

  final CircleMember member;
  final String circleId;
  final bool patientUsesApp;
  final bool patientIsYou;
  final bool canManageMembers;

  /// Whether the leader may hand the leadership to another member.
  final bool canHandOver;

  @override
  Widget build(BuildContext context) {
    final String photoPath = memberPhotoPath(
      member,
      circleId: circleId,
      patientIsYou: patientIsYou,
    );
    final Widget row = MemberOpenRow(
      member: member,
      photoPath: photoPath,
      patientUsesApp: patientUsesApp,
    );
    // The leader decides about the others who hold a membership, not about
    // themself or a patient who only reads their own day.
    if (!canManageMembers || member.isYou || !member.holdsMembership) {
      return row;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        row,
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MemberAccessControls(member: member, canHandOver: canHandOver),
        ),
      ],
    );
  }
}

/// Where a member's portrait is read from. A patient with their own account
/// is one person with one photo, read through the account endpoint so the
/// circle tab and the profile stay in sync.
String memberPhotoPath(
  CircleMember member, {
  required String circleId,
  required bool patientIsYou,
}) {
  if (!member.isPatient) return personPhotoPath(circleId, member.accountId);
  return patientIsYou
      ? AccountEndpoints.accountPhoto
      : CircleEndpoints.patientPhoto(circleId);
}

/// What the circle's leader («قائد الدائرة») decides about one member, in a
/// panel of its own under that member's row: a chip for each area they may
/// edit, then handing over the circle or taking the member out of it. The
/// panel keeps one member's controls from reading as the next member's.
/// Disabled while another change is on its way.
class MemberAccessControls extends StatelessWidget {
  const MemberAccessControls({
    super.key,
    required this.member,
    required this.canHandOver,
  });

  final CircleMember member;
  final bool canHandOver;

  @override
  Widget build(BuildContext context) {
    final bool acting = context.select(
      (CircleOverviewCubit cubit) => cubit.state.acting,
    );
    final String? accountId = member.accountId;
    final bool enabled = !acting && accountId != null;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('circle_overview.allow_editing'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          MemberAccessAreaChips(
            access: member.editAccess,
            accountId: accountId,
            enabled: enabled,
          ),
          const Divider(height: AppSpacing.lg),
          MemberAccessButtons(
            member: member,
            accountId: accountId,
            enabled: enabled,
            canHandOver: canHandOver,
          ),
        ],
      ),
    );
  }
}

/// A chip for each area a member may edit («medications», …), on when they
/// may.
/// A tap lets them or stops them, unless [enabled] is false.
class MemberAccessAreaChips extends StatelessWidget {
  const MemberAccessAreaChips({
    super.key,
    required this.access,
    required this.accountId,
    required this.enabled,
  });

  final EditAccess access;
  final String? accountId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String? accountId = this.accountId;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final String area in EditAccess.areas)
          FilterChip(
            side: BorderSide.none,
            label: Text(context.tr('circle_overview.area.$area')),
            selected: access.of(area),
            onSelected: enabled && accountId != null
                ? (bool allowed) => changeMemberAccess(
                    context,
                    accountId,
                    area: area,
                    allowed: allowed,
                  )
                : null,
          ),
      ],
    );
  }
}

/// Lets a member edit [area] («medications», …) or not, then tells the
/// leader how it went.
Future<void> changeMemberAccess(
  BuildContext context,
  String accountId, {
  required String area,
  required bool allowed,
}) async {
  final String? error = await context
      .read<CircleOverviewCubit>()
      .setMemberEditAccess(accountId, area: area, allowed: allowed);
  if (!context.mounted) return;
  if (error != null) {
    AppToast.show(context, error, kind: ToastKind.error);
    return;
  }
  AppToast.showText(
    ScaffoldMessenger.of(context),
    context.tr(
      allowed ? 'toast.editing_allowed' : 'toast.editing_paused',
      args: <String>[context.tr('circle_overview.area.$area')],
    ),
  );
}
