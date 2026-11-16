import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/navigation/glass_icon_button.dart';
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
        // One edit button, in the corner: a pencil without a word,
        // like the close button. VoiceOver reads «تعديل».
        trailing: state.status == AccountStatus.ready
            ? GlassIconButton(
                tooltip: context.tr('account.edit'),
                icon: const Icon(AppIcons.pencil),
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
