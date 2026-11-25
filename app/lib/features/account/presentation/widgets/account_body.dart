import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_name_fields.dart';
import 'package:app/features/account/presentation/widgets/account_sections.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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
