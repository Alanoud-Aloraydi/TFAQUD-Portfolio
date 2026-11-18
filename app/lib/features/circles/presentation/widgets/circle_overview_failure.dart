import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The circle could not be read: why, and a button that reads it again.
class CircleOverviewFailure extends StatelessWidget {
  const CircleOverviewFailure({
    super.key,
    required this.errorKey,
    required this.onRetry,
  });

  final String? errorKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          context.tr(errorKey ?? 'error.unknown'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
      ],
    );
  }
}
