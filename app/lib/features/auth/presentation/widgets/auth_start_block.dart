import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «ابدأ» on the last page of the welcome, with the note on the terms.
class AuthStartBlock extends StatelessWidget {
  const AuthStartBlock({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PillButton(label: context.tr('auth.start'), onPressed: onStart),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('auth.terms_note'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
