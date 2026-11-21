import 'package:app/core/network/legal_page.dart';
import 'package:app/core/widgets/layout/action_row.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The privacy policy and the terms, each opening its page.
Widget accountLegalCard(BuildContext context) => SettingsCard(
  children: <Widget>[
    ActionRow(
      label: context.tr('legal.privacy'),
      onPressed: LegalPage.privacy.open,
    ),
    ActionRow(
      label: context.tr('legal.terms'),
      onPressed: LegalPage.terms.open,
    ),
  ],
);
