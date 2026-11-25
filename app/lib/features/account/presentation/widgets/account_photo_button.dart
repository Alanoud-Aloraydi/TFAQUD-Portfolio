import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/account_sent_request_row.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The account's photo with the small pencil badge on it. Tapping it opens
/// the sheet that takes or picks a new one; VoiceOver reads it as a button.
class AccountPhotoButton extends StatelessWidget {
  const AccountPhotoButton({
    required this.name,
    required this.avatarCode,
    required this.onSaved,
    super.key,
  });

  /// The name the sheet shows and the letter the avatar falls back to.
  final String name;
  final String? avatarCode;

  /// Called once a new photo is saved.
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken(context.tr('photos.edit_your_photo')),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showPersonPhotoSheet(
          context,
          title: context.tr('photos.your_photo'),
          name: name,
          photoPath: AccountEndpoints.accountPhoto,
          avatarPath: AccountEndpoints.accountAvatar,
          avatarCode: avatarCode,
          frontCamera: true,
          onSaved: onSaved,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PersonPhoto(
              name: name,
              photoPath: AccountEndpoints.accountPhoto,
              avatarCode: avatarCode,
              size: AppSizes.avatarLarge,
            ),
            const PhotoEditBadge(),
          ],
        ),
      ),
    );
  }
}

/// The requests this account sent that the patient has not answered yet.
/// Tapping one opens the sheet that can cancel it.
Widget accountAwaitingSection(
  BuildContext context, {
  required AccountCubit cubit,
  required List<SentCircleRequest> sent,
}) {
  return SettingsSection(
    title: context.tr('account.awaiting_title'),
    children: <Widget>[
      for (final SentCircleRequest request in sent)
        AccountSentRequestRow(
          request: request,
          onTap: () =>
              showSentRequestSheet(context, cubit: cubit, request: request),
        ),
    ],
  );
}

/// Opens the details of a request the account sent, with a button that cancels
/// it. The sheet is above the page, so it receives [cubit].
Future<void> showSentRequestSheet(
  BuildContext context, {
  required AccountCubit cubit,
  required SentCircleRequest request,
}) {
  return showGlassSheet<void>(
    context,
    title: context.tr('account.request_sheet_title'),
    builder: (BuildContext sheetContext) =>
        SentRequestDetails(cubit: cubit, request: request),
  );
}

/// What the sheet holds: the number, the mode, the status, and «إلغاء الطلب».
class SentRequestDetails extends StatelessWidget {
  const SentRequestDetails({
    super.key,
    required this.cubit,
    required this.request,
  });

  final AccountCubit cubit;
  final SentCircleRequest request;

  Future<void> _cancel(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool? yes = await showCancelRequestDialog(context);
    if (yes != true) return;
    final bool canceled = await cubit.cancelRequest(request.id);
    if (canceled) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool accepted = request.status == CircleRequestStatus.accepted;
    // The glass sheet draws the title.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SentRequestLine(
          label: context.tr('circles.patient_phone_label'),
          child: Text(
            SaudiMobile.display(request.patientPhoneNumber),
            textDirection: TextDirection.ltr,
            style: text.bodyMedium,
          ),
        ),
        SentRequestModeLine(mode: request.proposedAppMode),
        SentRequestStatusLine(accepted: accepted),
        const SizedBox(height: AppSpacing.lg),
        SentRequestCancelButton(onPressed: () => _cancel(context)),
      ],
    );
  }
}

/// The app mode the request proposed, as a line of the sheet.
class SentRequestModeLine extends StatelessWidget {
  const SentRequestModeLine({super.key, required this.mode});

  final CircleAppMode mode;

  @override
  Widget build(BuildContext context) {
    return SentRequestLine(
      label: context.tr('circles.app_mode'),
      child: StatusBadge(
        text: context.tr(
          mode == CircleAppMode.detailed
              ? 'circles.mode_detailed'
              : 'circles.mode_simplified',
        ),
        tone: StatusTone.success,
      ),
    );
  }
}

/// Where the request stands, as a line of the sheet: accepted or pending.
class SentRequestStatusLine extends StatelessWidget {
  const SentRequestStatusLine({super.key, required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return SentRequestLine(
      label: context.tr('circles.request_status'),
      child: StatusBadge(
        icon: accepted ? ActionIcons.check : ScheduleIcons.clock,
        text: context.tr(
          accepted
              ? 'account.status_accepted'
              : 'circles.request_status_pending',
        ),
        tone: accepted ? StatusTone.success : StatusTone.attention,
      ),
    );
  }
}

/// «إلغاء الطلب», full width, in the error red.
class SentRequestCancelButton extends StatelessWidget {
  const SentRequestCancelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        // Cancelling a request cannot be undone: the error red.
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppSemanticColors.statusError,
          side: const BorderSide(color: AppSemanticColors.borderControlBase),
        ),
        child: Text(context.tr('circles.cancel_request')),
      ),
    );
  }
}

/// Renders the line element of sent request sheet.
class SentRequestLine extends StatelessWidget {
  const SentRequestLine({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
