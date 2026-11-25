import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/expand_reveal.dart';
import 'package:flutter/material.dart';

/// The white, edged, rounded card a [PlanItemCard] is drawn in, with the
/// item card's padding inside it.
class PlanItemFrame extends StatelessWidget {
  const PlanItemFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.m,
          side: const BorderSide(color: AppSemanticColors.borderSubtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppItemCard.padding),
        child: child,
      ),
    );
  }
}

/// The details of a [PlanItemCard] under a line, sliding down from the line
/// that opens them when [open].
class PlanItemDetails extends StatelessWidget {
  const PlanItemDetails({super.key, required this.open, required this.details});

  final bool open;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    return ExpandReveal(
      open: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[const Divider(), ...details],
      ),
    );
  }
}
