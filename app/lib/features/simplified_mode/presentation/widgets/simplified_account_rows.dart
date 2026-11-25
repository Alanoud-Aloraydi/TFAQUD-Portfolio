import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_header.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_legal.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_sync_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_notifications_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everything «حسابي» shows, in order: who the patient is, the text size
/// and هجري or ميلادي, whether the phone's notifications are allowed, the
/// calendar copy, the medical file, the privacy policy and terms, signing
/// out and deleting.
List<Widget> simplifiedAccountRows(
  BuildContext context,
  AccountState state,
  String? circleId,
) {
  final AccountSummary? account = state.account;
  return <Widget>[
    if (account != null)
      simplifiedAccountHeader(context, account)
    else if (state.status == AccountStatus.loading)
      const LoadingNote(),
    SimplifiedSectionTitle(context.tr('simplified_mode.display')),
    const SimplifiedTextSizeCard(),
    const SimplifiedCalendarCard(),
    SimplifiedSectionTitle(context.tr('account.notifications_title')),
    const SimplifiedNotificationsCard(),
    if (circleId != null) ...<Widget>[
      SimplifiedSectionTitle(context.tr('simplified_mode.calendar_title')),
      SimplifiedCalendarSyncCard(circleId: circleId),
      SimplifiedSectionTitle(context.tr('simplified_mode.my_info')),
      simplifiedAccountFileCard(context, circleId),
    ],
    SimplifiedSectionTitle(context.tr('legal.section')),
    ...simplifiedAccountLegal(context),
    const SizedBox(height: 8),
    const SimplifiedSignOutButton(),
    SimplifiedOutlinedDanger(
      label: context.tr('simplified_mode.delete_account'),
      busy: state.deleting,
      filled: false,
      onPressed: context.read<AccountCubit>().startDelete,
    ),
  ];
}

class SimplifiedSectionTitle extends StatelessWidget {
  const SimplifiedSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: SimplifiedStyle.head(SimplifiedStyle.body));
}
