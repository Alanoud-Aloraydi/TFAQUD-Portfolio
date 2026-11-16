import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/account/presentation/widgets/account_photo_button.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:flutter/material.dart';

/// The top of «حسابي»: the account's photo, with the full name and the phone
/// number under it.
class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    required this.account,
    required this.onPhotoSaved,
    super.key,
  });

  final AccountSummary account;

  /// Called once a new photo is saved, so the page reads the account again.
  final VoidCallback onPhotoSaved;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String shown = account.displayName.isNotEmpty
        ? account.displayName
        : account.fullName;
    return Column(
      children: <Widget>[
        AccountPhotoButton(
          name: shown,
          avatarCode: account.avatarCode,
          onSaved: onPhotoSaved,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(account.fullName, style: text.titleLarge),
        Text(
          SaudiMobile.display(account.phoneNumber),
          textDirection: TextDirection.ltr,
          style: text.bodySmall?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
