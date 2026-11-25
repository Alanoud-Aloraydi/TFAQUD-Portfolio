import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:flutter/material.dart';

/// The padded line of an [InsetTextRow]: the small label in its column,
/// the [field] after it, and an optional [trailing] control. A [multiline]
/// field lines the label up with its first line.
class InsetTextLine extends StatelessWidget {
  const InsetTextLine({
    super.key,
    required this.label,
    required this.field,
    required this.multiline,
    this.trailing,
  });

  final String label;
  final Widget field;
  final bool multiline;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment align = multiline
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: align,
          children: <Widget>[
            // The visible label and the field merge into one node, so
            // VoiceOver reads the label with the field.
            Expanded(
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: align,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                        top: multiline ? AppSpacing.md : 0,
                      ),
                      child: InsetRowLabel(label),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: field),
                  ],
                ),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

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
