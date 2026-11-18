import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The app's name over the welcome; it stays while the pages slide.
class AuthAppName extends StatelessWidget {
  const AuthAppName({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.touch,
      child: Center(
        child: Text(
          context.tr('auth.app_name'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
