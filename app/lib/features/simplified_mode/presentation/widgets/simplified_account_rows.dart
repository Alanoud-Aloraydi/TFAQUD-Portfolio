import 'package:app/core/widgets/forms/notifications_denied_watcher.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_file_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_header.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_sync_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_permission_denied.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_section_title.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_sign_out_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everything «حسابي» shows, in order: who the patient is, the text size,
/// the calendar copy, the medical file, signing out and deleting.
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
      const Center(child: CircularProgressIndicator()),
    SimplifiedSectionTitle(context.tr('simplified_mode.display')),
    const SimplifiedTextSizeCard(),
    if (circleId != null) ...<Widget>[
      const NotificationsDeniedWatcher(
        row: SimplifiedPermissionDenied(
          messageKey: 'circle_overview.notifications_denied',
        ),
      ),
      SimplifiedSectionTitle(context.tr('simplified_mode.calendar_title')),
      SimplifiedCalendarSyncCard(circleId: circleId),
      SimplifiedSectionTitle(context.tr('simplified_mode.my_info')),
      simplifiedAccountFileCard(context, circleId),
    ],
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
