import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/material.dart';

/// iOS inset grouped section, as in Settings and Health (design system
/// FormGroup): a header above a white card of rows divided by inset lines,
/// and an optional footer.
///
/// The card is radius-l; rows inside keep 16 side padding, so anything
/// rounded inside a row is radius-s (28 − 16).
class InsetGroup extends StatelessWidget {
  const InsetGroup({
    super.key,
    required this.children,
    this.header,
    this.headerAction,
    this.footer,
  });

  final List<Widget> children;
  final String? header;

  /// A small action at the end of the header, such as a delete button.
  final Widget? headerAction;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final ShapeBorder shape = AppSurfaces.cardShape();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (header != null || headerAction != null)
          Padding(
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
                      style: text.titleSmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ),
                ?headerAction,
              ],
            ),
          ),
        DecoratedBox(
          decoration: AppSurfaces.card(),
          child: Material(
            type: MaterialType.transparency,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: AppSizes.divider,
                      indent: AppSpacing.lg,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.inset,
              end: AppSpacing.inset,
              top: AppSpacing.labelGap,
            ),
            child: Text(footer!, style: text.bodySmall),
          ),
      ],
    );
  }
}
