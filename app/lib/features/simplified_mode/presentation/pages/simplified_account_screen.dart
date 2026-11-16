import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_notices.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «حسابي»: the patient's name and number, the text size and reading,
/// the calendar copy of appointments, the medical file, signing out and
/// deleting the account. Needs an [AccountCubit] and an [AuthCubit].
class SimplifiedAccountScreen extends StatelessWidget {
  const SimplifiedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? circleId = context.select<SimplifiedModeCubit, String?>(
      (cubit) => cubit.state.day?.circleId,
    );
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: simplifiedAccountNotable,
      listener: simplifiedAccountNotice,
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) => SimplifiedPage(
          title: context.tr('simplified_mode.account_title'),
          children: simplifiedAccountRows(context, state, circleId),
        ),
      ),
    );
  }
}
