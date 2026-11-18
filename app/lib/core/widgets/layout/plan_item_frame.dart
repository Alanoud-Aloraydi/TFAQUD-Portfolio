import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
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
