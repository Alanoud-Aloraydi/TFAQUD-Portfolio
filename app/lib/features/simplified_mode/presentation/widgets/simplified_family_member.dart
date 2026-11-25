import 'dart:async';

import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SimplifiedFamilyMember extends StatelessWidget {
  const SimplifiedFamilyMember({
    super.key,
    required this.member,
    required this.circleId,
  });

  final CircleMember member;
  final String circleId;

  Future<void> _call() async {
    final String? phone = member.phoneNumber;
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken(
        context.tr('simplified_mode.call_member', args: <String>[member.name]),
      ),
      onTap: _call,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
        onTap: _call,
        child: SizedBox(
          width: 88,
          child: Column(
            children: <Widget>[
              SimplifiedFamilyMemberPhoto(member: member, circleId: circleId),
              const SizedBox(height: 6),
              Text(
                member.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SimplifiedStyle.head(SimplifiedStyle.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
