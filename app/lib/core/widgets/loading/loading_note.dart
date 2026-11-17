import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A page or a part of one that is loading, said the way a pulled page
/// says it: the loader, and «جارٍ التحميل» under it.
class LoadingNote extends StatelessWidget {
  const LoadingNote({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TfaqudLoader(size: 44),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('common.loading'),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.tokens.textSecondary),
          ),
        ],
      ),
    ),
  );
}
