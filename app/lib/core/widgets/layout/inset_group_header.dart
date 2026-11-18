import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The line above an [InsetGroup]'s card: its header, read as a heading,
/// and an optional small action at the end.
class InsetGroupHeader extends StatelessWidget {
  const InsetGroupHeader({super.key, this.header, this.headerAction});

  final String? header;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.inset,
        end: AppSpacing.xs,
        bottom: AppSpacing.labelGap,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                header ?? '',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            ),
          ),
          ?headerAction,
        ],
      ),
    );
  }
}
