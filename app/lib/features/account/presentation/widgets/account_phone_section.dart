import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/settings_section.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The verified phone number, shown but not editable.
class AccountPhoneSection extends StatelessWidget {
  const AccountPhoneSection({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: context.tr('account.phone'),
      children: [
        InfoRow(
          label: context.tr('account.phone'),
          value: SaudiMobile.display(phoneNumber),
          ltr: true,
        ),
      ],
    );
  }
}
