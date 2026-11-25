import 'package:app/core/network/legal_page.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/layout/action_row.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_actions_card.dart';
import 'package:app/features/account/presentation/widgets/account_calendar_card.dart';
import 'package:app/features/account/presentation/widgets/account_calendar_sync_card.dart';
import 'package:app/features/account/presentation/widgets/account_notifications_card.dart';
import 'package:app/features/account/presentation/widgets/account_photo_button.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Everything «حسابي» scrolls through, in order: who the account is, its
/// data, هجري or ميلادي, whether the phone's notifications are allowed,
/// calendar sync, the requests that wait for a patient, the note about the
/// medical file, the privacy policy and terms with the note that the app
/// does not replace a doctor, and the two actions that end the account.
List<Widget> accountSections(
  BuildContext context, {
  required AccountCubit cubit,
  required AccountState state,
  required AccountSummary account,
}) => <Widget>[
  AccountProfileHeader(account: account, onPhotoSaved: cubit.load),
  const SizedBox(height: AppSpacing.xl),
  accountDataSection(context, account),
  const SizedBox(height: AppSpacing.xl),
  const AccountCalendarCard(),
  const SizedBox(height: AppSpacing.xl),
  const AccountNotificationsCard(),
  if (state.circles.isNotEmpty) ...<Widget>[
    const SizedBox(height: AppSpacing.xl),
    AccountCalendarSyncCard(circles: state.circles),
  ],
  if (state.sent.isNotEmpty) ...<Widget>[
    const SizedBox(height: AppSpacing.xl),
    accountAwaitingSection(context, cubit: cubit, sent: state.sent),
  ],
  const SizedBox(height: AppSpacing.md),
  InsetText.note(context.tr('account.medical_note')),
  const SizedBox(height: AppSpacing.xl),
  accountLegalCard(context),
  const SizedBox(height: AppSpacing.md),
  InsetText.note(context.tr('legal.disclaimer')),
  const SizedBox(height: AppSpacing.xl),
  accountActionsCard(context, cubit: cubit, deleting: state.deleting),
];

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
