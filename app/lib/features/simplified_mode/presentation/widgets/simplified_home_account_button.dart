import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/network/account_endpoints.dart';

/// The patient's photo on the corner of «اليوم»: a tap opens their account.
class SimplifiedHomeAccountButton extends StatelessWidget {
  const SimplifiedHomeAccountButton({super.key, required this.day});

  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        label: spoken(context.tr('simplified_mode.account_title')),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push(Routes.simplifiedAccount),
          child: PersonPhoto(
            name: day.displayName ?? '',
            photoPath: AccountEndpoints.accountPhoto,
            avatarCode: day.avatarCode,
            size: SimplifiedStyle.touch,
          ),
        ),
      ),
    );
  }
}
