import 'dart:async';

import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_crop_page.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
