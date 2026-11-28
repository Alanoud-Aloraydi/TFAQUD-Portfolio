import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_city.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_legal.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_name.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_calendar_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_notifications_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «حسابي»: the patient's name and number, the names and the city to
/// change, the text size and reading, the calendar copy of appointments,
/// the medical file, signing out and deleting the account. Needs an
/// [AccountCubit] and an [AuthCubit].
class SimplifiedAccountScreen extends StatelessWidget {
  const SimplifiedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? circleId = context.select<SimplifiedModeCubit, String?>(
      (cubit) => cubit.state.day?.circleId,
    );
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: simplifiedAccountNotable,
      listener: simplifiedAccountNotice,
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) => SimplifiedPage(
          title: context.tr('simplified_mode.account_title'),
          children: simplifiedAccountRows(context, state, circleId),
        ),
      ),
    );
  }
}

/// A change in «حسابي» the patient must be told about: the session
/// ending, a sign-out, a failure, or the next question about deleting.
bool simplifiedAccountNotable(AccountState before, AccountState after) =>
    (after.sessionEnded && !before.sessionEnded) ||
    (after.signedOut && !before.signedOut) ||
    (after.errorKey != null && after.errorKey != before.errorKey) ||
    (after.deletePrompt != before.deletePrompt &&
        after.deletePrompt != DeletePrompt.none);

/// Leaves for the sign-in screen, shows a failure once, and asks the next
/// question of deleting.
void simplifiedAccountNotice(BuildContext context, AccountState state) {
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
      confirm: confirmSimplifiedDelete,
    );
  }
}

/// The first question of deleting, asked as a big sheet.
Future<bool?> confirmSimplifiedDelete(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: SimplifiedColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: simplifiedDeleteSheetBody(sheetContext),
      ),
    ),
  );
}

/// Everything «حسابي» shows, in order: who the patient is, their names,
/// their city, the text size and هجري or ميلادي, whether the phone's
/// notifications are allowed, the calendar copy, the medical file, the
/// privacy policy and terms, signing out and deleting.
List<Widget> simplifiedAccountRows(
  BuildContext context,
  AccountState state,
  String? circleId,
) {
  final AccountSummary? account = state.account;
  return <Widget>[
    if (account != null) ...<Widget>[
      simplifiedAccountHeader(context, account),
      SimplifiedSectionTitle(context.tr('simplified_mode.name_title')),
      SimplifiedAccountNameCard(account: account),
      SimplifiedSectionTitle(context.tr('simplified_mode.file.city')),
      SimplifiedAccountCityCard(account: account),
    ] else if (state.status == AccountStatus.loading)
      const LoadingNote(),
    SimplifiedSectionTitle(context.tr('simplified_mode.display')),
    const SimplifiedTextSizeCard(),
    const SimplifiedCalendarCard(),
    SimplifiedSectionTitle(context.tr('account.notifications_title')),
    const SimplifiedNotificationsCard(),
    if (circleId != null) ...<Widget>[
      SimplifiedSectionTitle(context.tr('simplified_mode.calendar_title')),
      SimplifiedCalendarSyncCard(circleId: circleId),
      SimplifiedSectionTitle(context.tr('simplified_mode.my_info')),
      simplifiedAccountFileCard(context, circleId),
    ],
    SimplifiedSectionTitle(context.tr('legal.section')),
    ...simplifiedAccountLegal(context),
    const SizedBox(height: 8),
    const SimplifiedSignOutButton(),
    SimplifiedOutlinedDanger(
      label: context.tr('simplified_mode.delete_account'),
      busy: state.deleting,
      filled: false,
      onPressed: context.read<AccountCubit>().startDelete,
    ),
  ];
}

class SimplifiedSectionTitle extends StatelessWidget {
  const SimplifiedSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: SimplifiedStyle.head(SimplifiedStyle.body));
}

/// The top of «حسابي»: the photo beside the name and the number.
Widget simplifiedAccountHeader(BuildContext context, AccountSummary account) =>
    Row(
      children: <Widget>[
        simplifiedAccountPhoto(context, account),
        const SizedBox(width: SimplifiedStyle.gap),
        simplifiedAccountIdentity(context, account),
      ],
    );

/// The patient's name, number and the hint that the photo can be changed,
/// read out as one. The number reads left to right.
Widget simplifiedAccountIdentity(
  BuildContext context,
  AccountSummary account,
) => Expanded(
  child: MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          account.displayName,
          style: SimplifiedStyle.head(SimplifiedStyle.headline),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            SaudiMobile.display(account.phoneNumber),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
        ),
        Text(
          context.tr('simplified_mode.photo_hint'),
          style: SimplifiedStyle.text(SimplifiedStyle.caption),
        ),
      ],
    ),
  ),
);

/// The patient's photo on «حسابي», tapped to change it, with the small
/// edit badge on its corner.
Widget simplifiedAccountPhoto(BuildContext context, AccountSummary account) =>
    MergeSemantics(
      child: Semantics(
        button: true,
        label: spoken(context.tr('simplified_mode.change_photo')),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => unawaited(
            showPersonPhotoSheet(
              context,
              title: context.tr('photos.your_photo'),
              name: account.displayName,
              photoPath: AccountEndpoints.accountPhoto,
              avatarPath: AccountEndpoints.accountAvatar,
              avatarCode: account.avatarCode,
              frontCamera: true,
              onSaved: () => unawaited(context.read<AccountCubit>().load()),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              PersonPhoto(
                name: account.displayName,
                photoPath: AccountEndpoints.accountPhoto,
                avatarCode: account.avatarCode,
                size: 72,
              ),
              const PhotoEditBadge(),
            ],
          ),
        ),
      ),
    );
