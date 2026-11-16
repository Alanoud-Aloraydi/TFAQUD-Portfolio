import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «ملفي الطبي» as one big card that opens the simplified medical file.
Widget simplifiedAccountFileCard(BuildContext context, String circleId) =>
    SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      onTap: () => context.push(Routes.simplifiedMedicalFile(circleId)),
      child: MergeSemantics(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.tr('simplified_mode.my_medical_file'),
                    style: SimplifiedStyle.head(SimplifiedStyle.body),
                  ),
                  Text(
                    context.tr('simplified_mode.my_medical_file_sub'),
                    style: SimplifiedStyle.text(SimplifiedStyle.caption),
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.next, size: 28, color: SimplifiedStyle.ink),
          ],
        ),
      ),
    );
