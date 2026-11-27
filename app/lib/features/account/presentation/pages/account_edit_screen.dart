import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_content.dart';
import 'package:app/features/account/presentation/widgets/account_edit_fields.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen editor of the account's names and city; the verified phone
/// number stays read-only.
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
                    city: city,
                    onCity: pickCity,
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

/// What the editor holds while it is open: the three names being typed, the
/// city picked, whether the account filled them yet, the names left empty
/// and the save in flight.
mixin AccountEditFlow<T extends StatefulWidget> on State<T> {
  final first = TextEditingController();
  final last = TextEditingController();
  final display = TextEditingController();

  /// The account's city, then the one picked; null for an account made
  /// before onboarding asked, until one is picked.
  String? city;
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

  /// Puts the account's names and city in the fields, once.
  void fill(AccountSummary? account) {
    if (filled || account == null) return;
    first.text = account.firstName;
    last.text = account.lastName;
    display.text = account.displayName;
    city = account.city;
    filled = true;
  }

  /// Opens the city sheet; a confirmed city replaces the shown one.
  Future<void> pickCity() async {
    final String? picked = await showCitySheet(context, selected: city);
    if (picked != null && mounted) setState(() => city = picked);
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
      city: city,
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
