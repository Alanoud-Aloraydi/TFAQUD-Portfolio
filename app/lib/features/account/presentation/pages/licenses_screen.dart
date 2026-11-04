import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Displays the licenses screen UI.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            StepHeader(
              title: context.tr('photos.licenses'),
              onClose: context.pop,
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString(
                  'assets/avatars/LICENSE_fluentui-emoji.txt',
                ),
                builder: (context, snapshot) => ListView(
                  children: [
                    Text(context.tr('photos.avatar_credit')),
                    const SizedBox(height: AppSpacing.md),
                    SelectableText(snapshot.data ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
