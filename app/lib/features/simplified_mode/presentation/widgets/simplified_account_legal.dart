import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/network/legal_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
