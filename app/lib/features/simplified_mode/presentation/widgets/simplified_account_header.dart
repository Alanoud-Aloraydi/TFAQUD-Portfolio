import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_identity.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The top of «حسابي»: the photo beside the name and the number.
Widget simplifiedAccountHeader(BuildContext context, AccountSummary account) =>
    Row(
      children: <Widget>[
        simplifiedAccountPhoto(context, account),
        const SizedBox(width: SimplifiedStyle.gap),
        simplifiedAccountIdentity(context, account),
      ],
    );
