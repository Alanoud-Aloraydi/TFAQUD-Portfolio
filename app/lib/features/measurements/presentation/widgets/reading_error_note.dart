import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Why the reading was not saved, in the error colour.
class ReadingErrorNote extends StatelessWidget {
  const ReadingErrorNote({super.key, required this.errorKey});

  final String errorKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Text(
      context.tr(errorKey),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
