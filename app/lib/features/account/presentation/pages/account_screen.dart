import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_skeleton.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/account/presentation/widgets/sent_request_sheet.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:app/features/account/presentation/widgets/sign_out_row.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/request_age.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "حسابي": the person's names and phone number, the circles that wait for the
/// patient's approval, sign-out and deleting the account. Needs an
/// [AccountCubit] and an AuthCubit above it.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _edit(BuildContext context, AccountCubit cubit) async {
    final saved = await context.push<bool>(Routes.accountEdit);
    if (saved == true && !cubit.isClosed) await cubit.load();
  }

  /// Asks the question of the delete flow that the cubit is waiting on.
  Future<void> _ask(
    BuildContext context,
    AccountCubit cubit,
    DeletePrompt prompt,
  ) async {
    switch (prompt) {
      case DeletePrompt.none:
        return;
      case DeletePrompt.confirm:
        final bool? agreed = await showDeleteConfirmDialog(context);
        if (agreed == true) {
          await cubit.confirmDelete();
        } else {
          cubit.cancelDelete();
        }
      case DeletePrompt.patientChoice:
        final PatientChoice? choice = await showPatientChoiceDialog(context);
        if (choice == null) {
          cubit.cancelDelete();
        } else {
          await cubit.choosePatient(choice);
        }
      case DeletePrompt.lastManager:
        final bool? agreedToAll = await showLastManagerDialog(context);
        if (agreedToAll == true) {
          await cubit.confirmLastManager();
        } else {
          cubit.cancelDelete();
        }
    }
  }

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
            listenWhen: (AccountState before, AccountState after) =>
                (after.sessionEnded && !before.sessionEnded) ||
                (after.signedOut && !before.signedOut) ||
                (after.errorKey != null && after.errorKey != before.errorKey) ||
                (after.noticeKey != null &&
                    after.noticeKey != before.noticeKey) ||
                (after.deletePrompt != before.deletePrompt &&
                    after.deletePrompt != DeletePrompt.none),
            listener: (BuildContext context, AccountState state) {
              if (state.sessionEnded || state.signedOut) {
                context.go(Routes.auth);
                return;
              }
              final String? key = state.errorKey ?? state.noticeKey;
              if (key != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(context.tr(key))));
                cubit.messagesShown();
              }
              if (state.deletePrompt != DeletePrompt.none) {
                _ask(context, cubit, state.deletePrompt);
              }
            },
            builder: (BuildContext context, AccountState state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StepHeader(
                    title: context.tr('account.title'),
                    // The page is a modal: the close button takes it down.
                    onClose: context.canPop()
                        ? () => context.pop()
                        : () => context.go(Routes.today),
                    // One button edits the names, as in the handoff: both
                    // name rows open the same page.
                    trailing: state.status == AccountStatus.ready
                        ? TextButton.icon(
                            onPressed: () => _edit(context, cubit),
                            icon: const Icon(
                              AppIcons.pencil,
                              size: AppSizes.iconSmall,
                            ),
                            label: Text(context.tr('account.edit')),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    // Loading, error and content fade into each other.
                    child: ContentSwitcher(
                      stateKey: state.status,
                      child: _body(context, cubit, state),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AccountCubit cubit, AccountState state) {
    switch (state.status) {
      case AccountStatus.loading:
        return const AccountSkeleton();
      case AccountStatus.failure:
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
      case AccountStatus.ready:
        return _ready(context, cubit, state, state.account!);
    }
  }

  Widget _ready(
    BuildContext context,
    AccountCubit cubit,
    AccountState state,
    AccountSummary account,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final String shown = account.displayName.isNotEmpty
        ? account.displayName
        : account.fullName;
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () => showPersonPhotoSheet(
                  context,
                  title: context.tr('photos.your_photo'),
                  name: shown,
                  photoPath: ApiEndpoints.accountPhoto,
                  avatarPath: ApiEndpoints.accountAvatar,
                  avatarCode: account.avatarCode,
                  frontCamera: true,
                  onSaved: cubit.load,
                ),
                child: PersonPhoto(
                  name: shown,
                  photoPath: ApiEndpoints.accountPhoto,
                  avatarCode: account.avatarCode,
                  size: AppSizes.avatarLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(account.fullName, style: text.titleLarge),
              Text(
                RequestSentView.displayPhone(account.phoneNumber),
                textDirection: TextDirection.ltr,
                style: text.bodySmall?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsSection(
            title: context.tr('account.my_data'),
            children: <Widget>[
              InfoRow(
                label: context.tr('account.display_name'),
                value: account.displayName,
              ),
              InfoRow(
                label: context.tr('account.full_name'),
                value: account.fullName,
              ),
              InfoRow(
                label: context.tr('account.phone'),
                value: RequestSentView.displayPhone(account.phoneNumber),
                ltr: true,
              ),
            ],
          ),
          if (state.sent.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            SettingsSection(
              title: context.tr('account.awaiting_title'),
              children: <Widget>[
                for (final SentCircleRequest request in state.sent)
                  _SentRequestRow(
                    request: request,
                    onTap: () => showSentRequestSheet(
                      context,
                      cubit: cubit,
                      request: request,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          InsetText.note(context.tr('account.medical_note')),
          const SizedBox(height: AppSpacing.xl),
          SettingsCard(
            children: <Widget>[
              ActionRow(
                label: context.tr('photos.licenses'),
                onPressed: () => context.push(Routes.licenses),
              ),
              const SignOutRow(),
              ActionRow(
                label: context.tr('account.delete_account'),
                color: AppSemanticColors.statusError,
                busy: state.deleting,
                onPressed: cubit.startDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One circle that waits for the patient: the word it is named with, how long
/// ago the request was sent, and where it stands.
class _SentRequestRow extends StatelessWidget {
  const _SentRequestRow({required this.request, required this.onTap});

  final SentCircleRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool accepted = request.status == CircleRequestStatus.accepted;
    final int? days = RequestAge.days(request.createdAt, DateTime.now());
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: AppSizes.avatar,
              height: AppSizes.avatar,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppSemanticColors.selectedSurface,
                shape: BoxShape.circle,
              ),
              child: Text(
                request.circleLabel.isEmpty
                    ? '؟'
                    : request.circleLabel.characters.first,
                style: text.titleMedium?.copyWith(
                  color: AppSemanticColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(request.circleLabel, style: text.titleMedium),
                  if (days != null)
                    Text(
                      _ageText(context, days),
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusPill(
              icon: accepted ? AppIcons.check : AppIcons.clock,
              text: context.tr(
                accepted
                    ? 'account.status_accepted_short'
                    : 'circles.request_status_pending',
              ),
              background: accepted
                  ? AppSemanticColors.background
                  : AppSemanticColors.background,
              foreground: accepted
                  ? AppSemanticColors.statusSuccess
                  : context.tokens.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            // Mirrored on a right-to-left screen: it points to the end of the row.
            Icon(AppIcons.forward, color: context.tokens.textSecondary),
          ],
        ),
      ),
    );
  }

  /// "أُرسل الطلب اليوم", "قبل يومين", "قبل 5 أيام". The number is written 0-9.
  String _ageText(BuildContext context, int days) {
    if (days == 0) return context.tr('account.sent_today');
    if (days == 1) return context.tr('account.sent_yesterday');
    if (days == 2) return context.tr('account.sent_two_days');
    return context.tr(
      days <= 10 ? 'account.sent_days_few' : 'account.sent_days_many',
      args: <String>['$days'],
    );
  }
}
