import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The family to call, one tap each. More than three scroll sideways,
/// never into more rows, so the squares below stay in reach.
class SimplifiedFamilyCard extends StatelessWidget {
  const SimplifiedFamilyCard({
    super.key,
    required this.family,
    required this.circleId,
  });

  final List<CircleMember> family;
  final String circleId;

  /// What the card says: its title, then each person's name.
  static List<String> lines(BuildContext context, List<CircleMember> family) =>
      <String>[
        _title(context, family),
        for (final CircleMember member in family) member.name,
      ];

  /// More than three people scroll sideways, and the title says so.
  static String _title(BuildContext context, List<CircleMember> family) =>
      context.tr(
        family.length > 3
            ? 'simplified_mode.family_title_swipe'
            : 'simplified_mode.family_title',
      );

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      padding: const EdgeInsets.all(SimplifiedStyle.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _title(context, family),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final CircleMember member in family)
                  SimplifiedFamilyMember(member: member, circleId: circleId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
