import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';
import 'package:app/core/network/circle_endpoints.dart';

/// A family member's photo with the green phone badge on its corner.
class SimplifiedFamilyMemberPhoto extends StatelessWidget {
  const SimplifiedFamilyMemberPhoto({
    super.key,
    required this.member,
    required this.circleId,
  });

  final CircleMember member;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        PersonPhoto(
          name: member.name,
          photoPath: CircleEndpoints.memberPhoto(
            circleId,
            member.accountId ?? '',
          ),
          avatarCode: member.avatarCode,
          size: 72,
        ),
        PositionedDirectional(
          bottom: -2,
          end: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SimplifiedColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: SimplifiedColors.surface, width: 3),
            ),
            child: const Icon(
              PeopleIcons.phoneCall,
              size: 14,
              color: SimplifiedColors.surface,
            ),
          ),
        ),
      ],
    );
  }
}
