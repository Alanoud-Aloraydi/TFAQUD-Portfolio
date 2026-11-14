import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// One switch per category (doses, measurements, appointments), each this
/// circle's own setting — someone in several circles may want only one
/// circle's appointments on their phone's calendar, say.
/// «الأعضاء», and at the end how many members and pending invitations
/// there are: «3 أعضاء · دعوة معلّقة».
class CircleMembersHeader extends StatelessWidget {
  const CircleMembersHeader({super.key, required this.overview});

  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int invitations = overview.pendingInvitations.length;
    final String summary = <String>[
      _count(context, 'members_count', overview.members.length),
      if (invitations > 0) _count(context, 'invitations', invitations),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.labelGap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              context.tr('circle_overview.members'),
              style: text.headlineMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              summary,
              textAlign: TextAlign.end,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Arabic counting for members and invitations.
  /// The number is written 0-9.
  static String _count(BuildContext context, String noun, int count) {
    final String key = switch (count) {
      1 => 'one',
      2 => 'two',
      <= 10 => 'few',
      _ => 'many',
    };
    return context.tr('circle_overview.${noun}_$key', args: <String>['$count']);
  }
}
