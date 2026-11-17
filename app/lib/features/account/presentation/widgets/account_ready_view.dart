import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_sections.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:flutter/material.dart';

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
