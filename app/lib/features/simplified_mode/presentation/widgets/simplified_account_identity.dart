import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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
