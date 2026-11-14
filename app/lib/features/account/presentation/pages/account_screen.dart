import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/layout/action_row.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/core/widgets/layout/settings_section.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_calendar_sync_card.dart';
import 'package:app/features/account/presentation/widgets/account_sent_request_row.dart';
import 'package:app/features/account/presentation/widgets/account_skeleton.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/account/presentation/widgets/sent_request_sheet.dart';
import 'package:app/features/account/presentation/widgets/sign_out_row.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
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
                AppToast.show(
                  context,
                  key,
                  kind: state.errorKey != null
                      ? ToastKind.error
                      : ToastKind.success,
                );
                cubit.messagesShown();
              }
              if (state.deletePrompt != DeletePrompt.none) {
                answerDeletePrompt(context, cubit, state.deletePrompt);
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
              Semantics(
                button: true,
                label: context.tr('photos.edit_your_photo'),
                child: InkWell(
                  customBorder: const CircleBorder(),
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PersonPhoto(
                        name: shown,
                        photoPath: ApiEndpoints.accountPhoto,
                        avatarCode: account.avatarCode,
                        size: AppSizes.avatarLarge,
                      ),
                      const PhotoEditBadge(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(account.fullName, style: text.titleLarge),
              Text(
                SaudiMobile.display(account.phoneNumber),
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
                value: SaudiMobile.display(account.phoneNumber),
                ltr: true,
              ),
            ],
          ),
          if (state.circles.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            AccountCalendarSyncCard(circles: state.circles),
          ],
          if (state.sent.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            SettingsSection(
              title: context.tr('account.awaiting_title'),
              children: <Widget>[
                for (final SentCircleRequest request in state.sent)
                  AccountSentRequestRow(
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
