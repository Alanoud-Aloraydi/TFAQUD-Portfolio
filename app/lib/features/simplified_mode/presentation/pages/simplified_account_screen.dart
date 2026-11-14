import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_sync_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_section_title.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_sign_out_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_card.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
      listenWhen: (before, after) =>
          (after.sessionEnded && !before.sessionEnded) ||
          (after.signedOut && !before.signedOut) ||
          (after.errorKey != null && after.errorKey != before.errorKey) ||
          (after.deletePrompt != before.deletePrompt &&
              after.deletePrompt != DeletePrompt.none),
      listener: (context, state) {
        final AccountCubit cubit = context.read<AccountCubit>();
        if (state.sessionEnded || state.signedOut) {
          context.go(Routes.auth);
          return;
        }
        if (state.errorKey case final String key) {
          AppToast.show(
            context,
            key,
            kind: state.errorKey != null ? ToastKind.error : ToastKind.success,
          );
          cubit.messagesShown();
        }
        if (state.deletePrompt != DeletePrompt.none) {
          answerDeletePrompt(
            context,
            cubit,
            state.deletePrompt,
            confirm: _confirmDelete,
          );
        }
      },
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          final account = state.account;
          return SimplifiedPage(
            title: context.tr('simplified_mode.account_title'),
            children: <Widget>[
              if (account != null)
                Row(
                  children: <Widget>[
                    Semantics(
                      button: true,
                      label: context.tr('simplified_mode.change_photo'),
                      excludeSemantics: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => unawaited(
                          showPersonPhotoSheet(
                            context,
                            title: context.tr('photos.your_photo'),
                            name: account.displayName,
                            photoPath: ApiEndpoints.accountPhoto,
                            avatarPath: ApiEndpoints.accountAvatar,
                            avatarCode: account.avatarCode,
                            frontCamera: true,
                            onSaved: () =>
                                unawaited(context.read<AccountCubit>().load()),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            PersonPhoto(
                              name: account.displayName,
                              photoPath: ApiEndpoints.accountPhoto,
                              avatarCode: account.avatarCode,
                              size: 72,
                            ),
                            const PhotoEditBadge(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: SimplifiedStyle.gap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            account.displayName,
                            style: SimplifiedStyle.head(
                              SimplifiedStyle.headline,
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              SaudiMobile.display(account.phoneNumber),
                              style: SimplifiedStyle.text(
                                SimplifiedStyle.caption,
                              ),
                            ),
                          ),
                          Text(
                            context.tr('simplified_mode.photo_hint'),
                            style: SimplifiedStyle.text(
                              SimplifiedStyle.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else if (state.status == AccountStatus.loading)
                const Center(child: CircularProgressIndicator()),
              SimplifiedSectionTitle(context.tr('simplified_mode.display')),
              const SimplifiedTextSizeCard(),
              if (circleId != null) ...<Widget>[
                SimplifiedSectionTitle(
                  context.tr('simplified_mode.calendar_title'),
                ),
                SimplifiedCalendarSyncCard(circleId: circleId),
                SimplifiedSectionTitle(context.tr('simplified_mode.my_info')),
                SimplifiedCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SimplifiedStyle.pad,
                    vertical: SimplifiedStyle.gap,
                  ),
                  onTap: () =>
                      context.push(Routes.simplifiedMedicalFile(circleId)),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.tr('simplified_mode.my_medical_file'),
                              style: SimplifiedStyle.head(SimplifiedStyle.body),
                            ),
                            Text(
                              context.tr('simplified_mode.my_medical_file_sub'),
                              style: SimplifiedStyle.text(
                                SimplifiedStyle.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        AppIcons.next,
                        size: 28,
                        color: SimplifiedStyle.ink,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const SimplifiedSignOutButton(),
              SimplifiedOutlinedDanger(
                label: context.tr('simplified_mode.delete_account'),
                busy: state.deleting,
                filled: false,
                onPressed: context.read<AccountCubit>().startDelete,
              ),
            ],
          );
        },
      ),
    );
  }

  /// The first question of deleting, asked as a big sheet.
  static Future<bool?> _confirmDelete(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: SimplifiedStyle.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                sheetContext.tr('simplified_mode.delete_title'),
                style: SimplifiedStyle.head(26),
              ),
              const SizedBox(height: 8),
              Text(
                sheetContext.tr('simplified_mode.delete_text'),
                style: SimplifiedStyle.text(
                  SimplifiedStyle.body,
                  weight: AppTextTheme.medium,
                ),
              ),
              const SizedBox(height: 20),
              SimplifiedButton(
                label: sheetContext.tr('simplified_mode.delete_yes'),
                tone: SimplifiedButtonTone.danger,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 12),
              SimplifiedButton(
                label: sheetContext.tr('simplified_mode.delete_no'),
                tone: SimplifiedButtonTone.quiet,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
