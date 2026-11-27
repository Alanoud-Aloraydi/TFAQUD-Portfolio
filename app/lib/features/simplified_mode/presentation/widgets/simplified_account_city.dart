import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «المدينة» on «حسابي»: the account's city, whose weather «اليوم» shows.
/// A tap opens the city sheet and saves the city confirmed there.
class SimplifiedAccountCityCard extends StatelessWidget {
  const SimplifiedAccountCityCard({super.key, required this.account});

  final AccountSummary account;

  Future<void> _change(BuildContext context) async {
    final String? picked = await showCitySheet(context, selected: account.city);
    if (picked == null || !context.mounted) return;
    final String? error = await context.read<AccountCubit>().saveProfile(
      firstName: account.firstName,
      lastName: account.lastName,
      displayName: account.displayName,
      city: picked,
    );
    if (!context.mounted) return;
    if (error != null) {
      AppToast.show(context, error, kind: ToastKind.error);
      return;
    }
    // «اليوم» shows the new city's weather.
    unawaited(context.read<SimplifiedModeCubit>().load());
  }

  @override
  Widget build(BuildContext context) => SimplifiedCard(
    padding: const EdgeInsets.symmetric(
      horizontal: SimplifiedStyle.pad,
      vertical: SimplifiedStyle.gap,
    ),
    onTap: () => unawaited(_change(context)),
    child: MergeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              account.city ?? context.tr('circles.city_hint'),
              style: SimplifiedStyle.head(SimplifiedStyle.body),
            ),
          ),
          const Icon(ArrowIcons.next, size: 28, color: SimplifiedColors.ink),
        ],
      ),
    ),
  );
}
