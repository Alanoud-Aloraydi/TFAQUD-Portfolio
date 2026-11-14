import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
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
      label: context.tr(
        'simplified_mode.call_member',
        args: <String>[member.name],
      ),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
        onTap: _call,
        child: SizedBox(
          width: 88,
          child: Column(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  PersonPhoto(
                    name: member.name,
                    photoPath: ApiEndpoints.memberPhoto(
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
                        color: SimplifiedStyle.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SimplifiedStyle.surface,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        AppIcons.phoneCall,
                        size: 14,
                        color: SimplifiedStyle.surface,
                      ),
                    ),
                  ),
                ],
              ),
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
