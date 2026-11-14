import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A "nothing here yet" note, with an optional action such as opening the
/// add sheet. One note style for every empty place in the application.
class EmptyStateNote extends StatelessWidget {
  /// Inline under something else, such as the readings of a chosen day: as
  /// tall as the note itself.
  const EmptyStateNote(
    this.message, {
    super.key,
    this.actionLabel,
    this.onAction,
  }) : _fillsSection = false;

  /// A whole empty tab or section. The note takes the room the list would
  /// have filled and sits a little above its middle, where the eye lands,
  /// instead of clinging under the tabs.
  const EmptyStateNote.section(
    this.message, {
    super.key,
    this.actionLabel,
    this.onAction,
  }) : _fillsSection = true;

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool _fillsSection;

  /// How much of the screen an empty section keeps for itself, within
  /// bounds that suit both a small phone and a tall one.
  static const double _share = 0.42;
  static const double _least = 240;
  static const double _most = 420;

  @override
  Widget build(BuildContext context) {
    final Widget note = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.tokens.textSecondary),
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            // Filled, not a bare text link: a clear, tappable button.
            child: FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(AppIcons.plus, size: 18),
              label: Text(actionLabel!),
            ),
          ),
      ],
    );
    if (!_fillsSection) {
      // Full width even inside a start-aligned column, only as tall as the
      // note.
      return Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: note,
      );
    }
    final double reserved = (MediaQuery.sizeOf(context).height * _share).clamp(
      _least,
      _most,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: reserved),
      // Above the middle: a note sitting dead centre reads as low on a tall
      // phone.
      child: Align(alignment: const Alignment(0, -0.25), child: note),
    );
  }
}
