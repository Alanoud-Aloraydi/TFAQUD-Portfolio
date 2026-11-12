import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_skeleton.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_section.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/account/presentation/widgets/sent_request_sheet.dart';
import 'package:app/features/account/presentation/widgets/sign_out_row.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/request_age.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
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
            _CalendarSyncCard(circles: state.circles),
          ],
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

/// «مزامنة مع تقويم الجهاز» the way iOS Settings lays out a list of
/// switches. One circle: its three switches. Several (a manager may be in
/// many): one group with a row per circle, its patient's photo and how many
/// switches are on, closed until tapped, so the page stays short. One
/// shared explanation below.
class _CalendarSyncCard extends StatelessWidget {
  const _CalendarSyncCard({required this.circles});

  final List<CareCircleSummary> circles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.tr('circle_overview.calendar_sync_title')),
        if (circles.length == 1)
          CalendarSyncToggles(circleId: circles.single.id)
        else
          CalendarSyncCircleList(
            circles: <CalendarSyncCircle>[
              for (final CareCircleSummary circle in circles)
                (
                  id: circle.id,
                  name: circle.name,
                  leading: PersonPhoto(
                    name: circle.patientName ?? circle.name,
                    // The patient with their own account has one photo:
                    // the account's.
                    photoPath: circle.isPatient
                        ? ApiEndpoints.accountPhoto
                        : ApiEndpoints.patientPhoto(circle.id),
                    avatarCode: circle.patientAvatarCode,
                    size: SettingsIconTile.size,
                  ),
                ),
            ],
          ),
        const CalendarSyncHint(),
      ],
    );
  }
}

/// One circle that waits for the patient: the number it was sent to, how
/// long ago, and where it stands. The circle has no name yet: the patient
/// names it when they complete the request.
class _SentRequestRow extends StatelessWidget {
  const _SentRequestRow({required this.request, required this.onTap});

  final SentCircleRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool accepted = request.status == CircleRequestStatus.accepted;
    final int? days = RequestAge.days(
      request.createdAt,
      PatientClockScope.of(context),
    );
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
              child: const Icon(
                AppIcons.phone,
                size: AppSizes.iconSmall,
                color: AppSemanticColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    SaudiMobile.display(request.patientPhoneNumber),
                    textDirection: TextDirection.ltr,
                    style: text.titleMedium,
                  ),
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
            StatusBadge(
              icon: accepted ? AppIcons.check : AppIcons.clock,
              text: context.tr(
                accepted
                    ? 'account.status_accepted_short'
                    : 'circles.request_status_pending',
              ),
              tone: accepted ? StatusTone.success : StatusTone.attention,
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
