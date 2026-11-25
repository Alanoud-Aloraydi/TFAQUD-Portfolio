import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_content.dart';
import 'package:app/features/account/presentation/widgets/account_name_fields.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen account name editor; the verified phone number stays read-only.
class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen>
    with AccountEditFlow<AccountEditScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: BlocConsumer<AccountCubit, AccountState>(
          listener: (context, state) {
            if (state.sessionEnded) {
              context.go(Routes.auth);
              return;
            }
            fill(state.account);
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountEditBar(
                onSave: state.status == AccountStatus.ready && !saving
                    ? save
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.status == AccountStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (state.status == AccountStatus.failure)
                AccountEditFailure(messageKey: state.messageKey)
              else
                Expanded(
                  child: AccountEditFields(
                    first: first,
                    last: last,
                    display: display,
                    phoneNumber: state.account!.phoneNumber,
                    requiredError: requiredError,
                    onChanged: refresh,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// What the name editor shows when the account could not be read: why, and
/// a retry.
class AccountEditFailure extends StatelessWidget {
  const AccountEditFailure({super.key, required this.messageKey});

  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr(messageKey ?? 'error.unknown'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: context.read<AccountCubit>().load,
          child: Text(context.tr('auth.retry')),
        ),
      ],
    );
  }
}

/// What the name editor holds while it is open: the three names being typed,
/// whether the account filled them yet, the names left empty and the save in
/// flight.
mixin AccountEditFlow<T extends StatefulWidget> on State<T> {
  final first = TextEditingController();
  final last = TextEditingController();
  final display = TextEditingController();
  bool filled = false;
  bool saving = false;

  // After a save with a name left empty: «هذا الحقل مطلوب» under it.
  bool showErrors = false;

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    display.dispose();
    super.dispose();
  }

  /// Puts the account's names in the fields, once.
  void fill(AccountSummary? account) {
    if (filled || account == null) return;
    first.text = account.firstName;
    last.text = account.lastName;
    display.text = account.displayName;
    filled = true;
  }

  /// Shows again what was typed, and the names still empty.
  void refresh() => setState(() {});

  /// «هذا الحقل مطلوب» under an empty name, after a save.
  String? requiredError(TextEditingController name) =>
      showErrors && name.text.trim().isEmpty
      ? context.tr('common.field_required')
      : null;

  Future<void> save() async {
    if (saving) return;
    final List<TextEditingController> names = [first, last, display];
    if (names.any((name) => name.text.trim().isEmpty)) {
      setState(() => showErrors = true);
      return;
    }
    setState(() => saving = true);
    final error = await context.read<AccountCubit>().saveProfile(
      firstName: first.text,
      lastName: last.text,
      displayName: display.text,
    );
    if (!mounted) return;
    if (error == null) {
      context.pop(true);
      return;
    }
    // About no one name: the server, or the connection.
    setState(() => saving = false);
    AppToast.show(context, error, kind: ToastKind.error);
  }
}

/// The name editor's form: the first, last and display names, each a row
/// with «هذا الحقل مطلوب» under it when left empty, the display name's help
/// and the phone number read-only.
class AccountEditFields extends StatelessWidget {
  const AccountEditFields({
    super.key,
    required this.first,
    required this.last,
    required this.display,
    required this.phoneNumber,
    required this.requiredError,
    required this.onChanged,
  });

  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final String phoneNumber;

  /// The error under a name: «هذا الحقل مطلوب» when it is left empty.
  final String? Function(TextEditingController name) requiredError;

  /// Called when any of the names is typed in.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccountNameFields(
            first: first,
            last: last,
            display: display,
            requiredError: requiredError,
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.labelGap),
          InsetText.note(context.tr('account.display_name_help')),
          const SizedBox(height: AppSpacing.lg),
          AccountPhoneSection(phoneNumber: phoneNumber),
        ],
      ),
    );
  }
}

/// The verified phone number, shown but not editable.
class AccountPhoneSection extends StatelessWidget {
  const AccountPhoneSection({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: context.tr('account.phone'),
      children: [
        InfoRow(
          label: context.tr('account.phone'),
          value: SaudiMobile.display(phoneNumber),
          ltr: true,
        ),
      ],
    );
  }
}

/// "حسابي": the person's names and phone number, the circles that wait for the
/// patient's approval, sign-out and deleting the account. Needs an
/// [AccountCubit] and an AuthCubit above it.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountCubit cubit = context.read<AccountCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: BlocConsumer<AccountCubit, AccountState>(
            listenWhen: accountShouldListen,
            listener: (BuildContext context, AccountState state) =>
                accountListen(context, cubit, state),
            builder: (BuildContext context, AccountState state) =>
                accountContent(context, cubit, state),
          ),
        ),
      ),
    );
  }
}

/// The state changes «حسابي» answers with more than a repaint: the end of the
/// sign-in, a message to show once, and the next question about deleting.
bool accountShouldListen(AccountState before, AccountState after) =>
    (after.sessionEnded && !before.sessionEnded) ||
    (after.signedOut && !before.signedOut) ||
    (after.errorKey != null && after.errorKey != before.errorKey) ||
    (after.noticeKey != null && after.noticeKey != before.noticeKey) ||
    (after.deletePrompt != before.deletePrompt &&
        after.deletePrompt != DeletePrompt.none);

/// Goes to sign-in once the session is over, shows the one message the state
/// carries, and asks the next question of the delete flow.
void accountListen(
  BuildContext context,
  AccountCubit cubit,
  AccountState state,
) {
  if (state.sessionEnded || state.signedOut) {
    context.go(Routes.auth);
    return;
  }
  final String? key = state.errorKey ?? state.noticeKey;
  if (key != null) {
    AppToast.show(
      context,
      key,
      kind: state.errorKey != null ? ToastKind.error : ToastKind.success,
    );
    cubit.messagesShown();
  }
  if (state.deletePrompt != DeletePrompt.none) {
    answerDeletePrompt(context, cubit, state.deletePrompt);
  }
}
