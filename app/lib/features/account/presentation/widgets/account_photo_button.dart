import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/account_sent_request_row.dart';
import 'package:app/features/account/presentation/widgets/sent_request_details.dart';
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
