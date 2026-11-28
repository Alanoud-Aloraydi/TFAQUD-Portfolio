import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_name.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الاسم», opened from the simplified «حسابي»: the account's first, last
/// and display names in big fields, and «حفظ» at the bottom. It saves the
/// way the detailed mode's editor does ([AccountEditFlow]): a name left
/// empty says «هذا الحقل مطلوب» under it, and a save closes the page with
/// true. Needs an [AccountCubit] that reads the account.
class SimplifiedNameScreen extends StatefulWidget {
  const SimplifiedNameScreen({super.key});

  @override
  State<SimplifiedNameScreen> createState() => _SimplifiedNameScreenState();
}

class _SimplifiedNameScreenState extends State<SimplifiedNameScreen>
    with AccountEditFlow<SimplifiedNameScreen> {
  @override
  void initState() {
    super.initState();
    // The account may be read already, before the listener below exists.
    fill(context.read<AccountCubit>().state.account);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AccountCubit, AccountState>(
        listener: (context, state) {
          if (state.sessionEnded) {
            context.go(Routes.auth);
            return;
          }
          fill(state.account);
        },
        builder: (context, state) => SimplifiedPage(
          title: context.tr('simplified_mode.name_title'),
          backKey: 'simplified_mode.close',
          footer: state.status == AccountStatus.ready
              ? SimplifiedButton(
                  label: context.tr('account.save'),
                  onPressed: saving ? null : save,
                )
              : null,
          children: simplifiedNameRows(context, state),
        ),
      );

  /// The three names once the account is read; a spinner before, and the
  /// reason with «حاول مرة أخرى» when it could not be read.
  List<Widget> simplifiedNameRows(BuildContext context, AccountState state) =>
      switch (state.status) {
        AccountStatus.loading => const <Widget>[LoadingNote()],
        AccountStatus.failure => <Widget>[
          Text(
            context.tr(state.messageKey ?? 'error.unknown'),
            style: SimplifiedStyle.text(SimplifiedStyle.body),
          ),
          SimplifiedButton(
            label: context.tr('simplified_mode.try_again'),
            onPressed: context.read<AccountCubit>().load,
          ),
        ],
        AccountStatus.ready => <Widget>[
          SimplifiedNameField(
            label: context.tr('onboarding.first_name'),
            controller: first,
            limit: NameLimits.name,
            error: requiredError(first),
            onChanged: refresh,
          ),
          SimplifiedNameField(
            label: context.tr('onboarding.last_name'),
            controller: last,
            limit: NameLimits.name,
            error: requiredError(last),
            onChanged: refresh,
          ),
          SimplifiedNameField(
            label: context.tr('account.display_name'),
            controller: display,
            limit: NameLimits.displayName,
            error: requiredError(display),
            onChanged: refresh,
          ),
          Text(
            context.tr('account.display_name_help'),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ],
      };
}
