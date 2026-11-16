import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_actions_card.dart';
import 'package:app/features/account/presentation/widgets/account_awaiting_section.dart';
import 'package:app/features/account/presentation/widgets/account_calendar_sync_card.dart';
import 'package:app/features/account/presentation/widgets/account_data_section.dart';
import 'package:app/features/account/presentation/widgets/account_profile_header.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Everything «حسابي» scrolls through, in order: who the account is, its
/// data, calendar sync, the requests that wait for a patient, the note about
/// the medical file, and the two actions that end the account.
List<Widget> accountSections(
  BuildContext context, {
  required AccountCubit cubit,
  required AccountState state,
  required AccountSummary account,
}) => <Widget>[
  AccountProfileHeader(account: account, onPhotoSaved: cubit.load),
  const SizedBox(height: AppSpacing.xl),
  accountDataSection(context, account),
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
  accountActionsCard(context, cubit: cubit, deleting: state.deleting),
];
