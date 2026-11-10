import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// Defines the supported inset kind values.
enum _InsetKind { plain, header, note }

/// Text that stands outside a card: a small section label above a group of
/// cards or chips, or a note, a hint or an empty-list line under it.
///
/// It keeps 16 from both sides ([AppSpacing.inset]), so it lines up with the
/// text inside the cards, while the cards themselves reach the edges, as in
/// iOS grouped lists (the spacing rule in [AppSpacing]). A section title of
/// 22 is not one of these: it starts at the cards' edge.
class InsetText extends StatelessWidget {
  /// With [style], or the default text style when it is null.
  const InsetText(this.text, {super.key, this.style, this.textAlign})
    : _kind = _InsetKind.plain;

  /// A small grey section label, read as a header («فصيلة الدم»).
  const InsetText.header(this.text, {super.key})
    : style = null,
      textAlign = null,
      _kind = _InsetKind.header;

  /// A small grey note or hint under a group.
  const InsetText.note(this.text, {super.key, this.style})
    : textAlign = null,
      _kind = _InsetKind.note;

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final _InsetKind _kind;

  @override
  Widget build(BuildContext context) {
    final TextTheme theme = Theme.of(context).textTheme;
    final Color secondary = context.tokens.textSecondary;
    final TextStyle? resolved = switch (_kind) {
      _InsetKind.header => theme.titleSmall?.copyWith(color: secondary),
      _InsetKind.note => style ?? theme.bodySmall?.copyWith(color: secondary),
      _InsetKind.plain => style,
    };
    final Widget label = Text(text, style: resolved, textAlign: textAlign);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
      child: _kind == _InsetKind.header
          ? Semantics(header: true, child: label)
          : label,
    );
  }
}
