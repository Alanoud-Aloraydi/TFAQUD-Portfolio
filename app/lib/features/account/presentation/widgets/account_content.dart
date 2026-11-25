import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_name_fields.dart';
import 'package:app/features/account/presentation/widgets/account_sections.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
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

/// The top of the name editor: cancel, the title, and save, which waits
/// until the account is read and no save is running.
class AccountEditBar extends StatelessWidget {
  const AccountEditBar({super.key, required this.onSave});

  /// Null while saving is not possible.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.tr('common.cancel')),
        ),
        Expanded(
          child: Text(
            context.tr('account.edit_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        FilledButton(
          onPressed: onSave,
          child: Text(context.tr('account.save')),
        ),
      ],
    );
  }
}

/// What «حسابي» shows for each status: the skeleton while it loads, the
/// reason and a retry when the read failed, and the account itself.
Widget accountBody(
  BuildContext context,
  AccountCubit cubit,
  AccountState state,
) {
  switch (state.status) {
    case AccountStatus.loading:
      return const AccountSkeleton();
    case AccountStatus.failure:
      return _failure(context, cubit, state);
    case AccountStatus.ready:
      return accountReadyView(context, cubit, state, state.account!);
  }
}

/// Why the read failed, and a button that tries it again.
Widget _failure(BuildContext context, AccountCubit cubit, AccountState state) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.tr(state.messageKey ?? 'error.unknown'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: cubit.load,
          child: Text(context.tr('auth.retry')),
        ),
      ],
    ),
  );
}

/// The account itself: the page's sections in a list that pulls to refresh.
Widget accountReadyView(
  BuildContext context,
  AccountCubit cubit,
  AccountState state,
  AccountSummary account,
) {
  return LogoRefresh(
    onRefresh: cubit.load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: accountSections(
        context,
        cubit: cubit,
        state: state,
        account: account,
      ),
    ),
  );
}
