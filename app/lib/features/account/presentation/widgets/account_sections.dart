import 'package:app/app/router/routers.dart';
import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/network/legal_page.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/action_row.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/account_calendar_sync_card.dart';
import 'package:app/features/account/presentation/widgets/account_photo_button.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_alert.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Everything «حسابي» scrolls through, in order: who the account is, its
/// data, هجري or ميلادي, whether the phone's notifications are allowed,
/// calendar sync, the requests that wait for a patient, the note about the
/// medical file, the privacy policy and terms with the note that the app
/// does not replace a doctor, and the two actions that end the account.
List<Widget> accountSections(
  BuildContext context, {
  required AccountCubit cubit,
  required AccountState state,
  required AccountSummary account,
}) => <Widget>[
  AccountProfileHeader(account: account, onPhotoSaved: cubit.load),
  const SizedBox(height: AppSpacing.xl),
  accountDataSection(context, account),
  const SizedBox(height: AppSpacing.xl),
  const AccountCalendarCard(),
  const SizedBox(height: AppSpacing.xl),
  const AccountNotificationsCard(),
  if (state.circles.isNotEmpty) ...<Widget>[
    const SizedBox(height: AppSpacing.xl),
    AccountCalendarSyncCard(circles: state.circles),
  ],
  if (state.sent.isNotEmpty) ...<Widget>[
    const SizedBox(height: AppSpacing.xl),
    accountAwaitingSection(context, cubit: cubit, sent: state.sent),
  ],
  const SizedBox(height: AppSpacing.md),
  InsetText.note(context.tr('account.medical_note')),
  const SizedBox(height: AppSpacing.xl),
  accountLegalCard(context),
  const SizedBox(height: AppSpacing.md),
  InsetText.note(context.tr('legal.disclaimer')),
  const SizedBox(height: AppSpacing.xl),
  accountActionsCard(context, cubit: cubit, deleting: state.deleting),
];

/// The privacy policy and the terms, each opening its page.
Widget accountLegalCard(BuildContext context) => SettingsCard(
  children: <Widget>[
    ActionRow(
      label: context.tr('legal.privacy'),
      onPressed: LegalPage.privacy.open,
    ),
    ActionRow(
      label: context.tr('legal.terms'),
      onPressed: LegalPage.terms.open,
    ),
  ],
);

/// «بياناتي»: the name the app calls the person by, their full name, and the
/// phone number the account signs in with.
Widget accountDataSection(BuildContext context, AccountSummary account) {
  return SettingsSection(
    title: context.tr('account.my_data'),
    children: <Widget>[
      InfoRow(
        label: context.tr('account.display_name'),
        value: account.displayName,
      ),
      InfoRow(label: context.tr('account.full_name'), value: account.fullName),
      InfoRow(
        label: context.tr('account.phone'),
        value: SaudiMobile.display(account.phoneNumber),
        ltr: true,
      ),
    ],
  );
}

/// The last card of «حسابي»: signing out, and deleting the account.
Widget accountActionsCard(
  BuildContext context, {
  required AccountCubit cubit,
  required bool deleting,
}) {
  return SettingsCard(
    children: <Widget>[
      const SignOutRow(),
      ActionRow(
        label: context.tr('account.delete_account'),
        color: AppSemanticColors.statusError,
        busy: deleting,
        onPressed: cubit.startDelete,
      ),
    ],
  );
}

/// The "تسجيل الخروج" row. It needs an [AuthCubit] above it. The tokens are
/// removed from the phone even when the server cannot be reached.
class SignOutRow extends StatelessWidget {
  const SignOutRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (state is AuthErrorState) {
          AppToast.show(context, state.messageKey, kind: ToastKind.error);
        }
        if (state is AuthSignedOutState) {
          if (!state.serverConfirmed) {
            AppToast.show(
              context,
              'auth.sign_out_local_only',
              kind: ToastKind.error,
            );
          }
          context.go(Routes.auth);
        }
      },
      builder: (BuildContext context, AuthState state) {
        return ActionRow(
          label: context.tr('auth.sign_out'),
          // Signing out is a destructive action: the error red.
          color: AppSemanticColors.statusError,
          busy: state is AuthLoadingState,
          onPressed: () => _signOut(context),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (await askSignOutConfirmation(context) != true) return;
    if (!context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }
}

/// «التاريخ» in «حسابي»: هجري or ميلادي for every date of the app on this
/// phone, with today written in the chosen one under it.
class AccountCalendarCard extends StatelessWidget {
  const AccountCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final DateCalendar chosen = CalendarScope.of(context);
    final DateTime today = PatientClockScope.of(context).today();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitle(context.tr('calendar.title')),
        SettingsCard(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GlassSegmentedControl<DateCalendar>(
                segments: <DateCalendar, String>{
                  DateCalendar.hijri: context.tr('calendar.hijri'),
                  DateCalendar.gregorian: context.tr('calendar.gregorian'),
                },
                selected: chosen,
                onChanged: AppCalendar.choose,
              ),
            ),
          ],
        ),
        InsetText.note(
          context.tr(
            'calendar.note.${chosen.name}',
            args: <String>[
              context.tr('common.weekdays.${today.weekday}'),
              calendarDate(context, today),
            ],
          ),
        ),
      ],
    );
  }
}

/// The top of «حسابي»: the account's photo, with the full name and the phone
/// number under it.
class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    required this.account,
    required this.onPhotoSaved,
    super.key,
  });

  final AccountSummary account;

  /// Called once a new photo is saved, so the page reads the account again.
  final VoidCallback onPhotoSaved;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String shown = account.displayName.isNotEmpty
        ? account.displayName
        : account.fullName;
    return Column(
      children: <Widget>[
        AccountPhotoButton(
          name: shown,
          avatarCode: account.avatarCode,
          onSaved: onPhotoSaved,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(account.fullName, style: text.titleLarge),
        Text(
          SaudiMobile.display(account.phoneNumber),
          textDirection: TextDirection.ltr,
          style: text.bodySmall?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
