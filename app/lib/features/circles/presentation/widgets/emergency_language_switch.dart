import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «عربي / English»: two segments on a light track; the chosen one is
/// white with a line edge.
class EmergencyLanguageSwitch extends StatelessWidget {
  const EmergencyLanguageSwitch({
    super.key,
    required this.english,
    required this.onChanged,
  });

  final bool english;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.segmentTrack,
        shape: StadiumBorder(),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: EmergencySegment(
              label: context.tr('emergency_card.lang_ar'),
              selected: !english,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: EmergencySegment(
              label: 'English',
              selected: english,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class EmergencySegment extends StatelessWidget {
  const EmergencySegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppSemanticColors.surfaceContent
            : AppSemanticColors.transparent,
        shape: StadiumBorder(
          side: selected
              ? const BorderSide(color: AppSemanticColors.borderPlan)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _height,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppSemanticColors.textPrimary
                      : AppSemanticColors.textSupporting,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
