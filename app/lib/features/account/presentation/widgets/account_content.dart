import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_body.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// What «حسابي» puts on the screen: the page header with its close and edit
/// buttons, and whatever the status asks for below it.
Widget accountContent(
  BuildContext context,
  AccountCubit cubit,
  AccountState state,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      StepHeader(
        title: context.tr('account.title'),
        // The page is a modal: the close button takes it down.
        onClose: context.canPop()
            ? () => context.pop()
            : () => context.go(Routes.today),
        // The app's one edit affordance, as «الملف الصحي» shows it: the
        // header has room, so the pencil keeps its word.
        trailing: state.status == AccountStatus.ready
            ? EditAction(
                tooltip: context.tr('account.edit'),
                onPressed: () => _edit(context, cubit),
              )
            : null,
      ),
      const SizedBox(height: AppSpacing.lg),
      Expanded(
        // Loading, error and content fade into each other.
        child: ContentSwitcher(
          stateKey: state.status,
          child: accountBody(context, cubit, state),
        ),
      ),
    ],
  );
}

/// Opens the edit page and reads the account again when it saved.
Future<void> _edit(BuildContext context, AccountCubit cubit) async {
  final saved = await context.push<bool>(Routes.accountEdit);
  if (saved == true && !cubit.isClosed) await cubit.load();
}
