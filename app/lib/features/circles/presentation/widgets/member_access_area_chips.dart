import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/edit_access.dart';
import 'package:app/features/circles/presentation/widgets/member_access_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
