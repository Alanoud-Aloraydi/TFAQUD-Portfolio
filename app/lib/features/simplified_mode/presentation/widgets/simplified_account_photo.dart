import 'dart:async';

import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/core/network/account_endpoints.dart';

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
