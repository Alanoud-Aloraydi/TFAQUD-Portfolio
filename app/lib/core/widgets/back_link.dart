import 'package:app/core/constants/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The "رجوع" link at the top of a step page.
/// The back chevron (SF chevron.backward, CupertinoIcons.back) turns to
/// point right on an Arabic (right-to-left) screen, as iOS draws it.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(CupertinoIcons.back, size: 20),
        label: Text(context.tr('common.back')),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
