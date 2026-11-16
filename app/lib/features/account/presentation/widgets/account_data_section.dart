import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/settings_section.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «بياناتي»: the name the app calls the person by, their full name, and the
/// phone number the account signs in with.
Widget accountDataSection(BuildContext context, AccountSummary account) {
  return SettingsSection(
    title: context.tr('account.my_data'),
    children: <Widget>[
      InfoRow(
        label: context.tr('account.display_name'),
        value: account.displayName,
      ),
      InfoRow(label: context.tr('account.full_name'), value: account.fullName),
      InfoRow(
        label: context.tr('account.phone'),
        value: SaudiMobile.display(account.phoneNumber),
        ltr: true,
      ),
    ],
  );
}
