import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/network/legal_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The privacy policy and the terms as two big cards, then the note that
/// the app does not replace a doctor.
List<Widget> simplifiedAccountLegal(BuildContext context) => <Widget>[
  _card(context, 'legal.privacy', LegalPage.privacy),
  _card(context, 'legal.terms', LegalPage.terms),
  Text(
    context.tr('legal.disclaimer'),
    style: SimplifiedStyle.text(SimplifiedStyle.caption),
  ),
];

Widget _card(BuildContext context, String key, LegalPage page) =>
    SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      onTap: page.open,
      child: Semantics(
        link: true,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.tr(key),
                style: SimplifiedStyle.head(SimplifiedStyle.body),
              ),
            ),
            const Icon(ArrowIcons.next, size: 28, color: SimplifiedColors.ink),
          ],
        ),
      ),
    );

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
            const Icon(ArrowIcons.next, size: 28, color: SimplifiedColors.ink),
          ],
        ),
      ),
    );

/// Why a feature cannot work, at this mode's sizes, under its switch. As
/// in the detailed mode, the way back is the switch itself: turned on, it
/// says so and leaves for the phone's Settings (`leaveForSettings`).
class SimplifiedPermissionDenied extends StatelessWidget {
  const SimplifiedPermissionDenied({super.key, required this.messageKey});

  /// The sentence, such as `circle_overview.calendar_access_denied`.
  final String messageKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: 8,
      start: SimplifiedStyle.pad,
      end: SimplifiedStyle.pad,
    ),
    child: Text(
      context.tr(messageKey),
      style: SimplifiedStyle.text(
        SimplifiedStyle.caption,
        color: SimplifiedColors.attentionInk,
      ),
    ),
  );
}
