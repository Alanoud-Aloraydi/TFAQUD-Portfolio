import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A block inside a group that is not a row, such as chips that show every
/// choice at once instead of a row that opens a list (design system
/// FormGroup). It has the rows' side padding and room above and below.
/// [semanticLabel] names the block for VoiceOver, and [errorText] shows
/// under it with the error icon, as under a row.
class InsetBlock extends StatelessWidget {
  const InsetBlock({
    super.key,
    required this.child,
    this.semanticLabel,
    this.errorText,
  });

  final Widget child;
  final String? semanticLabel;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            child,
            if (errorText != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    AppIcons.warningCircle,
                    size: AppSizes.iconSmall,
                    color: tokens.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: tokens.errorText),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
