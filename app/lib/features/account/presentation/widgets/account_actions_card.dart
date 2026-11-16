import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/layout/action_row.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/sign_out_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The last card of «حسابي»: signing out, and deleting the account.
Widget accountActionsCard(
  BuildContext context, {
  required AccountCubit cubit,
  required bool deleting,
}) {
  return SettingsCard(
    children: <Widget>[
      const SignOutRow(),
      ActionRow(
        label: context.tr('account.delete_account'),
        color: AppSemanticColors.statusError,
        busy: deleting,
        onPressed: cubit.startDelete,
      ),
    ],
  );
}
