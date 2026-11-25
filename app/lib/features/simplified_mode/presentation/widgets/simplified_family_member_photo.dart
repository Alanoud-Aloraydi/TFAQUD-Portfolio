import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_person_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

/// Who comes along to a visit: «معك» and then each one, their photo
/// before their name.
class SimplifiedCompanions extends StatelessWidget {
  const SimplifiedCompanions({
    super.key,
    required this.circleId,
    required this.companions,
    this.onDark = false,
  });

  final String circleId;
  final List<AppointmentCompanion> companions;

  /// On the dark ground of a full-screen reminder, where it is centred.
  final bool onDark;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: onDark ? WrapAlignment.center : WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      Text(
        context.tr('simplified_mode.with_you'),
        style: SimplifiedStyle.label(
          SimplifiedStyle.caption,
          color: onDark ? SimplifiedColors.surface : SimplifiedColors.muted,
        ),
      ),
      for (final AppointmentCompanion one in companions)
        SimplifiedPersonChip(
          circleId: circleId,
          accountId: one.id,
          name: one.name,
          avatarCode: one.avatarCode,
          onDark: onDark,
        ),
    ],
  );
}
