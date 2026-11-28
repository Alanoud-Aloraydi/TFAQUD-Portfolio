import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الاسم» on «حسابي»: the account's first and last name. A tap opens the
/// page of the three names; after a save, «حسابي» and «اليوم» read the
/// account again, so the new name shows at once.
class SimplifiedAccountNameCard extends StatelessWidget {
  const SimplifiedAccountNameCard({super.key, required this.account});

  final AccountSummary account;

  Future<void> _edit(BuildContext context) async {
    final AccountCubit accountCubit = context.read<AccountCubit>();
    final SimplifiedModeCubit day = context.read<SimplifiedModeCubit>();
    final bool? saved = await context.push<bool>(Routes.simplifiedAccountName);
    if (saved != true) return;
    if (!accountCubit.isClosed) unawaited(accountCubit.load());
    // «صباح الخير، …» on «اليوم» says the new name.
    unawaited(day.load());
  }

  @override
  Widget build(BuildContext context) => SimplifiedCard(
    padding: const EdgeInsets.symmetric(
      horizontal: SimplifiedStyle.pad,
      vertical: SimplifiedStyle.gap,
    ),
    onTap: () => unawaited(_edit(context)),
    child: MergeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${account.firstName} ${account.lastName}',
              style: SimplifiedStyle.head(SimplifiedStyle.body),
            ),
          ),
          const Icon(ArrowIcons.next, size: 28, color: SimplifiedColors.ink),
        ],
      ),
    ),
  );
}

/// One name on the page of the names: its label above a big field, and
/// [error] under it in red. At most [limit] letters, as the server keeps.
class SimplifiedNameField extends StatelessWidget {
  const SimplifiedNameField({
    super.key,
    required this.label,
    required this.controller,
    required this.limit,
    required this.onChanged,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final int limit;
  final VoidCallback onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: 2),
    );
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(label, style: SimplifiedStyle.head(SimplifiedStyle.body)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLength: limit,
            inputFormatters: <CodePointLengthFormatter>[
              CodePointLengthFormatter(limit),
            ],
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedColors.ink,
              weight: AppTextTheme.medium,
            ),
            decoration: InputDecoration(
              counterText: '',
              errorText: error,
              errorStyle: SimplifiedStyle.text(
                SimplifiedStyle.caption,
                color: SimplifiedColors.danger,
              ),
              filled: true,
              fillColor: SimplifiedColors.surface,
              contentPadding: const EdgeInsets.all(18),
              border: border(SimplifiedColors.ink),
              enabledBorder: border(SimplifiedColors.ink),
              errorBorder: border(SimplifiedColors.danger),
              focusedErrorBorder: border(SimplifiedColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
